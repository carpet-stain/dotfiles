# 32. Rolling draft PR for backlog-manager memory sync

Date: 2026-07-25

## Status

Amends [ADR-0027](0027-scoped-pr-based-self-commit-for-backlog-manager-memory.md).

Superceded by [36. MCP knowledge-graph memory with a private local store](0036-mcp-knowledge-graph-memory-with-a-private-local-store.md)

## Context

ADR-0027's `git memory-pr` minted a new timestamped branch and opened a new
draft PR on every invocation, with no awareness of an existing open one. One
2026-07-24 session produced three competing memory-sync PRs, manual
reconciliation between them, and a `git reset --hard` that destroyed an
unrelated uncommitted `git/config` edit. The mechanism, not the operators, was
the defect — and ADR-0027's own revisit triggers (review-bypass practicality,
cross-repo memory, drafts piling up unreviewed) didn't name this failure mode,
so this amendment cites the incident directly (#414).

## Decision

Replace branch-per-invocation with **one fixed branch
(`chore/sync-backlog-memory`) carrying one rolling draft PR**. Every run
rebuilds the branch as a single fresh commit on top of fresh `origin/main`
from the working tree's memory dir — the working tree is the single source of
truth; never merge, never amend. Force-push with lease updates the open draft
in place.

The rolling draft is the **buffer that decouples write cadence from merge
cadence**: the agent syncs at session end, the human merges at their own
rhythm. A quietly-accumulating draft PR is expected-healthy — the buffer
working as designed, not the "drafts piling up unreviewed" failure ADR-0027
warned about. (Whether the human checkpoint itself is ever a bottleneck
is #411's question, not this one.)

Mechanics that carry the safety (details and their load-bearing comments live
in `scripts/backlog-memory-pr.sh`):

- **Fail loud everywhere; no auto-retry, no auto-recovery.** Every failure
  path prints the exact commands that resolve the state, matching
  `git-pr-link.sh` doctrine.
- **Stranded-delta check before the early-exit**, against fresh refs: a prior
  run that committed but failed to push can't be masked by a re-run's
  "nothing to sync."
- **Dirty guard before any ref moves**: tracked non-memory changes refuse the
  run (the incident's casualty was tracked-modified); untracked files never
  block — nothing in the script discards them.
- **Two-arm entry contract** against fresh `origin/main`: proceed only from
  the fixed branch (the state the script itself leaves behind) or a checkout
  whose non-memory tree equals fresh main. A feature-branch HEAD is refused
  cleanly, never surprise-flipped.
- **Branch entry** as `git switch -C` at HEAD (zero tree change) +
  `git reset --soft origin/main` (branch ref only) + a no-overlay
  `git restore` re-parenting the non-memory tree onto fresh main.
- **Lease-guarded pushes with fresh baselines**: the update path re-fetches
  the branch before `--force-with-lease`; the create path uses an
  empty-expectation lease (remote ref must not exist), so a lingering branch
  from a closed-unmerged PR fails loud instead of being overwritten.
- **Ready-for-review PR = the human's turn**: the script diverts to a
  timestamped branch and a new draft, touching nothing on the fixed branch.

## Alternatives considered

Seven plan-review rounds live in #414's comments; the significant rejections:

- **Reuse the newest existing sync branch (fetch, rebase onto main, squash
  into its commit)** — rejected: concentrates concurrent sessions onto the
  exact collision that caused the incident, and `commit --amend` rewrites the
  base commit — repo doctrine is reset-soft-then-fresh-commit, never amend.
- **Merge or rebase this run's delta with the branch's prior commit** —
  rejected: the working tree's memory dir is the single source of truth; a
  fresh snapshot each run means no conflict resolution can ever be needed.
- **Auto-retry on push failure / auto-delete a lingering remote branch /
  reopen a closed PR** — rejected: auto-recovery reintroduces the complexity
  the redesign removed and has its own failure modes in a solo-operator repo;
  fail loud with the concrete resolution instead.
- **"Just re-run" as the push-failure recovery story** — rejected: a naive
  re-run hits the nothing-to-sync early-exit and silently no-ops over a
  stranded delta; hence the startup stranded-delta check.
- **`git switch -C <branch> origin/main` (checkout with start-point) for
  branch entry** — rejected: with dirty memory files, checkout's two-way-merge
  rule refuses, wedging the primary rolling-accumulation path; entry must
  change no tree content.
- **Blocking on untracked files in the dirty guard** — rejected: the
  dangerous operations only endanger tracked state, and refusing on untracked
  files would make the script decline constantly — reintroducing the
  memory-never-commits failure ADR-0027 exists to fix.
- **Tolerating PR-lookup failure (`|| true`)** — rejected: falling through to
  the create path would silently reintroduce PR proliferation; a failed query
  aborts.

## Consequences

The agent-facing contract is unchanged: backlog-manager still runs
`git memory-pr` when done and nothing else; only the mechanism behind the
alias changed. ADR-0027's staging guard, draft-only rule, and human-merge
checkpoint (convention, not platform enforcement) all stand.

Accepted trades, recorded rather than solved: concurrent runs from linked
worktrees or separate clones are unsupported (single-checkout assumption; the
lease converts a race into a loud failure, not prevention), and a human
flipping the PR ready between the script's lookup and its push is a
low-risk TOCTOU — the next run routes correctly.

A force-pushed mutable commit means an audit of revision N is invalidated the
moment N+1 pushes — the audit-enforcement spike (#412) must bind its check to
the audited commit, not the PR.

Revisit if: the single-checkout assumption breaks in practice (a second
machine or persistent worktree starts running syncs), or #411 concludes the
human merge checkpoint needs automation on top of this buffer.

**Amended (2026-07-31, #498):** the primary-tree rebuild (`switch -C` +
`reset --soft` + `restore --source=origin/main`) forced two refusals —
tracked non-memory changes dirty, HEAD diverging from `origin/main` outside
the memory dir — that fired together in one routine sync (an
auto-maintenance-written `git/config` line, a stale local `main`, dirty
submodule pins), none of it related to memory. The single-checkout
assumption this ADR named above is retired along with them.

Replaced with a throwaway temp-index build: `git read-tree origin/main`
seeds a scratch index, `git add -A` — redirected to it via
`$GIT_INDEX_FILE`, never the real index — layers the memory dir's current
working-tree content on top, and `git commit-tree` produces a dangling
commit with no local ref ever created. The primary work-tree, index, and
HEAD are untouched **by construction**, not by an asserted invariant, so an
unrelated dirty file, a feature-branch HEAD, a stale local `main`, and a
dirty submodule pointer are all irrelevant — retiring both refusals outright
rather than special-casing around them.

The stranded-delta guard is retired too: its precondition — a local
`$FIXED_BRANCH` commit ahead of its remote because a prior run committed but
never pushed — cannot occur here. No persistent local commit exists to
strand; the built commit is a dangling object held only in a shell variable
until the push succeeds, so a failed push just leaves it for eventual git
garbage collection while the primary `$MEMORY_DIR` (the source of truth) is
untouched and the next run rebuilds cleanly from it.

Nothing-to-sync no longer reads local `git status`; it diffs the built
commit's `$MEMORY_DIR` content against a per-routing-path baseline —
`origin/$FIXED_BRANCH` on the update path, the newest existing timestamped
fork (falling back to `origin/$FIXED_BRANCH`) on the divert path, or
`origin/main` on the create path — so an idle run diffs clean under all
three routing states instead of forking a duplicate PR or re-pushing a no-op
that would invalidate a pending audit.

`--force-with-lease` becomes the sole concurrency guard, the former
double-checkout backstop having no analog here: every push uses the
explicit `<ref>:<expected-sha>` form, with the expectation read from a fetch
immediately preceding it, rather than the bare form that relied on a local
branch's own remote-tracking ref.

The staging guard also moves: ADR-0027's "verified by re-inspecting the
index after staging" is superseded by a tree-diff backstop
(`git diff --quiet origin/main <built-tree> -- . ':(exclude)$MEMORY_DIR'`)
run once against the built tree — a pathspec/glob-bug check, not a
per-invariant necessity, since `read-tree`-then-scoped-`add` should make it
a no-op diff by construction.

Everything else stands unchanged: one fixed branch, one rolling draft PR,
draft-only, human-merge-as-convention, fail-loud with no auto-retry. No new
ADR — only the rebuild mechanism moved (#498).
