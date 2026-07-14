# 16. Provenance-before-removal (Chesterton's Fence) for agents

Date: 2026-07-12

## Status

Accepted

## Context

Agents hit a recurring failure: see a surprising or unexplained line, judge it
dead, delete it, and reintroduce the exact bug a past commit fixed —
Chesterton's Fence for agents (#157). The intent that would stop this often
isn't in the file; it lives in history. This repo already engineered a complete,
intact provenance chain, so the trail is actually walkable: rebase-merge lands
the single Conventional Commit verbatim so `blame` points at a meaningful commit
not squash noise; `cliff.toml` resolves commit→PR via GitHub's API; `Closes #N`
links PR→issue; draft-PR journaling (#144) holds how the decision unfolded, not
just a final dump. Most repos can't walk that chain end to end; this one can, so
the ROI here is high (#157).

Existing "Verify, Don't Trust" covered fresh-retrieval of state but not
recovering intent before removal, and #142 required the new rule fold into that
paragraph rather than restate it (#157, 72e5dd2b).

## Decision

Add a deliberate provenance-recovery step before deleting or simplifying
surprising, load-bearing-but-unexplained code. Universal layer
(`claude/rules/universal/ai-collaboration.md`, extending "Verify, Don't Trust"):
recover a change's intent before treating it as removable — a comment is the
cheapest source, then the code's own history (blame → commit → PR/issue)
(72e5dd2b). Repo layer (AGENTS.md "When editing"): the concrete traversal
`git blame → git show → gh pr view --comments → gh issue view`, noting this
repo's rebase-merge, git-cliff PR-link resolution, and draft-PR journaling keep
that chain intact so the walk pays off (72e5dd2b).

Triggered by "about to delete or simplify something I can't explain," not every
edit; targeted retrieval of the one commit's PR/issue, not whole-history
slurping (#157). A strong nudge, not a guarantee — no hook can force it
(72e5dd2b, #157).

## Alternatives considered

- **Static-read-only removal — delete if it looks unused** — the failure mode
  the ADR exists to prevent: an agent reads only the current file, judges an odd
  line redundant, deletes it, and reintroduces the exact bug a past commit
  fixed. Intent frequently isn't in the file; a static read can't see the why
  history holds (#157).
- **Blanket "always git blame first" on every edit** — a context sink that
  mostly digs up nothing. Trigger provenance only on surprising /
  load-bearing-but-unexplained / about-to-delete code, and retrieve targeted
  (the one commit's PR/issue), not whole histories (#157).
- **Drop the code comment and rely on the history dig instead** — would backfire
  into under-commenting. The terse-why comment stays first-line defense —
  cheapest to read; the commit/PR/issue chain is the deep dig when the comment
  isn't enough. The rule does not excuse dropping the comment (#157).
- **A hook/gate that forces blame before deletion** — no hook can force an agent
  to read blame, so it can only be a strong nudge, not an enforced gate — same
  prose-only-unenforceable limit as the draft-PR-early rule (#147). Accepted
  because the trigger is memorable and high-value and the failure is soft: lost
  context, not corrupted state (#157).
- **Put the whole rule in AGENTS.md only** — recovering intent before removal is
  a general practice, so it belongs in the universal layer; AGENTS.md carries
  only the repo enabler (chain is intact here) plus the concrete path, as a
  signpost not a restatement — same principle-vs-instantiation split as
  #140/#142 (#157).

## Consequences

Easier: an agent about to delete unexplained code has a named, ordered path to
the why, and here that path resolves end to end. Harder/cost: a targeted history
dig on triggering edits, and the guidance is a nudge only — nothing enforces it
(#157). Embodied now in two places: the "Verify, Don't Trust" paragraph in
`claude/rules/universal/ai-collaboration.md` and the "When editing" provenance
bullet in AGENTS.md (72e5dd2b); compose-agents should carry the repo enabler
into any repo whose chain is actually intact (#157).

Revisit if a premise breaks the chain — switching off rebase-merge
(squash/merge-commit noise breaks blame→commit), dropping git-cliff's commit→PR
link resolution, or abandoning `Closes #N` / draft-PR journaling (#144) — any of
which makes the traversal unreliable and weakens the payoff; inferred from the
premises #157 names, not stated there as an explicit revisit trigger.
