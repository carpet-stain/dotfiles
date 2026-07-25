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
  `spike` (time-boxed research/decision). No dedicated `chore`/`refactor` label — those map to
  `enhancement` + a `type(scope):` title.
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

**Sweep disciplines** (each learned from a real miss):

- Spot-check labels lagging their own convention, not just untriaged issues — a label created
  *for* a pair of issues can end up never backfilled onto them.
- A cross-referenced issue can be **deleted** out from under an epic (`gh api` → 410, not
  closed). Closed is fine to leave; a 410 means repoint the epic to where the outcome lives.

**Epics use native GitHub sub-issues** (epic bodies also carry a checkbox breakdown). Attach:

    SUB_ID=$(gh api repos/:owner/:repo/issues/<CHILD_NUM> --jq '.id')   # numeric .id, NOT the issue number
    gh api --method POST repos/:owner/:repo/issues/<PARENT_NUM>/sub_issues -F sub_issue_id="$SUB_ID"

Gotcha: the API wants the child's integer database `id`, passed with `-F` (typed) not `-f`
(string), or it 422s. Good epic examples to match: #42, #97.

**Pointers, not restatements** (each home owns its detail):

- Credential reality in agent shells (scoped `GH_TOKEN`, direnv export, elevation): AGENTS.md's
  Credentials section — #160's fix landed there; don't re-derive from old memory.
- Why format hooks can't switch to `--write` while CI shares the lint command: AGENTS.md's
  `just format` note + #406. Recurs for any lefthook job tempted by `stage_fixed`.
- Format-before-lint job order and related lint-gap work: #405-#410.
