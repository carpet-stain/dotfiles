---
name: gh-conventions
description: Backlog conventions and gh mechanics for the carpet-stain/dotfiles repo (labels, epics, sub-issues, milestones)
metadata:
  type: reference
---

Repo `carpet-stain/dotfiles` backlog conventions (verify with `gh label list` — labels evolve):

- **Titles**: Conventional-Commit style `type(scope): imperative desc`. The issue-form templates'
  scope comment (`.github/ISSUE_TEMPLATE/spike.yml`) is the current scope source if it and
  AGENTS.md ever disagree. Scopeless titles are fine, especially for epics; new scopes are fine —
  flag on first use.
- **Type labels**: `bug, enhancement, documentation`, plus `epic` (large multi-part) and
  `spike` (question + deliverable, no timebox). No dedicated `chore`/`refactor` label — those map
  to `enhancement` + a `type(scope):` title.
- **Priority**: `priority: high/medium/low`. Every issue gets one. **`priority:` IS the
  timeline** (user is timeline-free by preference): high/medium/low = now/next/later. "What's
  next" = `--label 'priority: high'` minus `--label blocked`. Run the query live; never cache
  the answer.
- **Grouping axes — two, deliberately distinct**: a **milestone** is a body of work with a
  finish line (thematic, not SemVer — the SemVer milestones exist but sit unused); a **`theme:`
  label** is a perpetual area. Rule: NO per-commit-scope labels (`area: zsh` etc.) — the title
  scope owns that; theme labels capture only what a scope can't (cross-cutting). A theme earns
  a label at ~3+ issues sharing it, not speculatively.
- **Workflow state**: `blocked`, plus the plan-pipeline pair `needs-plan-review`/`plan-approved`
  (landed via #305, terraform-synced by infra). Discipline: label = at-a-glance flag, reason =
  comment/native blocked-by link (gh has no dependency subcommand — API-only). Deliberately no
  `needs-info`/`needs-decision`/`in-progress`.
- **Retired solo-repo defaults**: `help wanted`, `question`, `invalid` — no external
  contributors. Kept `duplicate`/`wontfix` (real dispositions).
- **`release-watch` issues get a priority label too** (default `priority: low`); `agent-ready`
  only if verification is non-interactive — a GUI/TUI eyeball check isn't, per AGENTS.md's
  carve-out.

**Sweep procedure**: see the `groom-backlog` skill — the generic checklist (untriaged,
priority re-weigh, dedupe, label drift, 410 repoints, rollups, ready-vs-blocked) lives there now,
not here.

**Repo-specific sweep discipline** (learned from a real miss):

- The release watcher dedupes against nothing: it can flag a version an open issue already
  covers (#462 vs #383, both fzf v0.74.1). When triaging a `release-watch` batch, check each
  flagged tool/version against open release-watch issues and fold dupes into the older one.

**Epics use native GitHub sub-issues** (epic bodies also carry a checkbox breakdown). Attach:

    SUB_ID=$(gh api repos/:owner/:repo/issues/<CHILD_NUM> --jq '.id')   # numeric .id, NOT the issue number
    gh api --method POST repos/:owner/:repo/issues/<PARENT_NUM>/sub_issues -F sub_issue_id="$SUB_ID"

Gotcha: the API wants the child's integer database `id`, passed with `-F` (typed) not `-f`
(string), or it 422s. Good epic examples to match: #42, #97.

**Native blocked-by dependencies** (the "reason via native link" half of the `blocked` discipline —
distinct from sub-issues). Same integer-`id` + `-F` shape:

    BLOCKER_ID=$(gh api repos/:owner/:repo/issues/<BLOCKER_NUM> --jq '.id')
    gh api --method POST repos/:owner/:repo/issues/<BLOCKED_NUM>/dependencies/blocked_by -F issue_id="$BLOCKER_ID"

GET the same path to read/verify (`.[].number`). Used for #476→#517 and #518→#516 (spike #431
follow-ups). Note: a native blocked-by link carries the sequencing, so the `blocked` *label* is
reserved for the decision/actionability block — drop the label once the gating decision lands even
if a build-order dependency remains (that's what the native link is for).

**Pointers, not restatements** (each home owns its detail):

- Credential reality in agent shells (scoped `GH_TOKEN`, direnv export, elevation): AGENTS.md's
  Credentials section — #160's fix landed there; don't re-derive from old memory.
- Why format hooks can't switch to `--write` while CI shares the lint command: AGENTS.md's
  `just format` note + #406. Recurs for any lefthook job tempted by `stage_fixed`.
- Format-before-lint job order and related lint-gap work: #405-#410.
