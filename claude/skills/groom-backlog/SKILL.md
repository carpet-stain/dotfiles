---
name: groom-backlog
description: >-
  Runs a periodic backlog sweep: find untriaged issues, re-weigh priorities, dedupe, tighten weak
  issues, catch labels that have drifted from the repo's own conventions, verify epic children
  still exist, propose epic rollups, and surface what's ready versus blocked. Use when asked to
  groom, sweep, or do backlog maintenance on a GitHub issue tracker. Repo-agnostic — reads the
  repo's own label taxonomy and conventions at runtime; repo-specific checks live in that repo's
  own notes, read as the last step.
---

# Groom Backlog

The periodic pass that keeps a backlog trustworthy. Leave it smaller and sharper than you found
it.

## Sweep

1. **Find untriaged issues from live state.** An open issue with no `priority:` label (or this
   repo's equivalent) hasn't been triaged — the absence is the marker. Classify it (type +
   priority).
2. **Re-weigh priorities.** A stale priority is worse than none — weigh impact against effort
   against current facts, not the label as it was set.
3. **Dedupe.** Search before filing; fold true duplicates into the older or more complete issue,
   confirming it's still open first.
4. **Tighten weak issues.** Vague titles, missing acceptance criteria, no reproduction steps —
   sharpen in place or mark what's missing.
5. **Check labels against the repo's own conventions.** A label scheme drifts — a `status:` value
   that's stopped being used, a `theme:` that's grown too broad, a convention stated in
   AGENTS.md/README that issues no longer follow.
6. **Verify epic children still exist.** A referenced child issue returning 404/410 isn't closed —
   it was deleted or renumbered. Repoint the epic, don't leave a dead reference.
7. **Propose epic rollups.** When 3+ open standalone issues share one concrete deliverable — not
   just a common theme label — propose consolidating them under a new or existing epic.
8. **Surface ready versus blocked.** A short list: what's actually next to act on, and what's
   blocked and why.
9. **Read the repo's sweep notes.** Repo-specific checks — a known dupe-folding pattern, a label
   quirk unique to this backlog — live in that repo's own memory or docs, not here. Read them last
   and apply them alongside the generic sweep above.

## Non-goals

Bulk relabeling, closing many issues, or restructuring milestones wholesale still needs a human
nod first — this skill proposes, it doesn't execute destructive moves unsupervised.
