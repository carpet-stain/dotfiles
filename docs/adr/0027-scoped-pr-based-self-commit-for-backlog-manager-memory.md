# 27. Scoped PR-based self-commit for backlog-manager memory

Date: 2026-07-18

## Status

Accepted

## Context

ADR-0009 gave backlog-manager committed, file-based memory but explicitly kept it
out of backlog-manager's own hands: "backlog-manager has no git access and its
lane stops at issues/labels/memory content, not repo mutation; a human in the
repo commits it opportunistically instead." That human-commit-gate depends on a
human noticing a dirty working tree, and it's already failing to scale past one
repo — dotfiles' memory sat modified-and-uncommitted across a prior session, and
infra's `.claude/agent-memory/backlog-manager/` was never committed at all since
it was created, fully untracked (#332). #314 already showed a stale memory write
silently regressing committed knowledge once; #315 (the `audit-memory` skill)
exists because the human-commit-gate alone didn't reliably catch that. ADR-0009
itself named the trigger for revisiting this: "the agent gains repo-write access
(drop the human-commit step) ... or this goes multi-repo." Both have now
happened (#332/#333).

## Decision

Give backlog-manager one narrow, scoped path to reach git history: a
machine-global `git memory-pr` alias (`scripts/backlog-memory-pr.sh`, deployed
the same way as `git pr`/`git squash`/`git new`) that is the _only_ sanctioned
way its memory changes get committed — never a raw `git commit`/`git push` from
the agent. Mechanically, Bash access for backlog-manager is already
unrestricted — nothing today stops it from running arbitrary git commands. This
decision doesn't change that trust model (no new hook/sandbox, consistent with
epic #298's rejection of heavy PreToolUse guard infra); it scaffolds the scoped
path as the sanctioned one and instructs the agent to use only it
(`claude/agents/backlog-manager.md`).

The script: no-ops if the current repo has no
`.claude/agent-memory/backlog-manager/` (no repo allow-list needed — the
directory's existence is the gate); branches off fresh `origin/main`; stages
_only_ `.claude/agent-memory/backlog-manager/**`, verified by re-inspecting the
index after staging (a guard against a pathspec/quoting bug, not against
unrelated dirty files elsewhere in the tree, which the pathspec already
excludes); commits as `chore(claude): sync backlog-manager memory`; pushes; and
opens a **draft** PR whose body separates the two things a reviewer should check
— run `audit-memory` for regression/staleness/duplication, and read it by hand
for secrets, since audit-memory has no secret-scanning capability at all. The
script **stops at draft** — it never calls `gh pr ready` or `gh pr merge`. A
human reviews and merges by hand, restoring the read-checkpoint ADR-0009 was
protecting, one step later in the pipeline than before.

That human-merge checkpoint is **convention, enforced by instruction, not by
the platform** — and this is a deliberate, explicit gap, not a guarantee it
isn't. Both dotfiles and infra are solo-owned: GitHub doesn't let an owner
approve their own PR under a standard required-review rule, so a real
`required_approving_review_count: 1` gate would block the human's own PRs too,
not just the agent's, unless narrowly bypass-scoped to the owner. Whether a
same-account API token merging on the agent's behalf would even be
distinguishable from the owner clicking merge (for bypass purposes) is
genuinely unverified — not a foundation to build a security boundary on.
Accepted as convention instead, matching ADR-0009's own boundary (also never
platform-enforced — Bash was always unrestricted). What's actually new here
isn't a capability the agent lacked; it's the sanctioned, scaffolded,
memory-scoped workflow around a capability that already existed.

## Alternatives considered

- **Direct push to `main`, no PR** — rejected: removes the last review
  checkpoint instead of shoring it up. #314 already showed a stale memory write
  regressing committed knowledge once, and #315 exists because the
  human-commit-gate alone didn't reliably catch it.
- **A platform-enforced required-review rule on these PRs** — considered and
  rejected for now: both repos are solo-owned, so a standard
  `required_approving_review_count` gate would also block the human's own PRs.
  Whether a scoped bypass or a same-account token is distinguishable from the
  owner merging directly is unverified; convention is the honest boundary until
  that's answered.
- **A hook/sandbox restricting Bash to the memory path** — rejected: heavier
  runtime infra than epic #298 already decided against; the scoped script plus
  instruction achieves the same practical boundary without it.
- **Auto-finalize the PR (draft → ready → merge)** — rejected: removes the
  human read-checkpoint that's the actual safety net for both regression and
  secret-leak risk. `audit-memory` covers the former only; a human read is the
  only coverage for the latter.
- **A single centralized cross-repo memory store instead of per-repo committed
  memory** — not decided here; whether per-repo self-commit is the complete
  answer to working multiple repos in one session, or the memory tool itself
  needs to reach across repos, is the sibling spike #334's question, evaluated
  against this mechanism as a working example.

## Consequences

Backlog-manager gains a repo-mutation capability (branch, push, open a PR) that
ADR-0009 explicitly withheld — mechanically scoped to
`.claude/agent-memory/backlog-manager/**` by the script's staging guard, and
draft-only: the script itself never issues `gh pr ready` or `gh pr merge`. This
partially reverses ADR-0009's "have the subagent commit its own memory"
rejected alternative — not a full reversal, since the underlying rationale (a
human reads the diff before it lands) is preserved, just moved one step later
in the pipeline (human-commits → human-merges-a-reviewed-draft-PR).

The human-merge checkpoint is convention, not enforcement, stated plainly so it
isn't mistaken for a guarantee. If draft PRs pile up unreviewed, the "someone
forgets" failure mode this decision exists to fix could re-manifest one layer
up — a draft PR nobody merges is no better than an uncommitted working tree.
Worth a follow-up if that happens in practice, not solved here.

`audit-memory` (#315) covers regression, staleness, and duplication only; it
has no secret-scanning capability, so a human read stays the sole coverage for
a leaked credential or token in memory content — the PR template says so
explicitly rather than letting "I ran audit-memory" read as "I checked for
secrets."

Validated by running the script against both dotfiles' own dirty memory and
infra's previously fully-untracked `.claude/agent-memory/backlog-manager/`
directory — see the two resulting sync PRs linked from #333, the latter
landing that directory's first-ever commit through this flow rather than a
manual one-off.

Revisit if: GitHub adds an owner-scoped required-review bypass that makes
platform enforcement of the merge checkpoint practical, #334 concludes memory
needs a cross-repo mechanism instead of per-repo self-commit, or draft PRs are
observed piling up unreviewed in practice.
