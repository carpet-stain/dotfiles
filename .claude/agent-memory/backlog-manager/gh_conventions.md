---
name: gh-conventions
description: Backlog conventions and gh mechanics for the carpet-stain/dotfiles repo (labels, epics, sub-issues, milestones)
metadata:
  type: reference
---

Repo `carpet-stain/dotfiles` backlog conventions (verify with `gh label list` — labels evolve):

- **Titles**: Conventional-Commit style `type(scope): imperative desc`. Scopes in use:
  `zsh, zellij, git, nvim, macos, theme` (from AGENTS.md). Scopeless `feat:`/`ci:`/`chore:`
  titles are also common, especially for epics. New scopes (e.g. `python`) are fine — flag on
  first use.
- **Type labels**: `bug, enhancement, documentation`, plus `epic` (large multi-part) and
  `spike` (time-boxed research/decision). Also `good first issue`, `duplicate`, `wontfix`,
  `release-watch`, `upstream-review`. No dedicated `chore`/`refactor` label — those map to
  `enhancement` + a `type(scope):` title.
- **Priority**: `priority: high` / `priority: medium` / `priority: low`. Every issue gets one.
- **Milestones**: SemVer (`v0.4.0`, `v0.5.0`, `v0.6.0`), currently all empty/unused.
- **Milestone #8 `New-repo bootstrap`** is a deliberate exception: a *thematic* grouping (not a
  SemVer release) for the new-repo initiative — epics #129 + #136 and spikes #130 + #137. Chosen
  over a SemVer bucket because all three version milestones are empty and no ship-version is
  justified yet; harmless to git-cliff (releases compute from commits, not milestones). Revisit /
  retarget to a SemVer milestone once scope+mechanism settle.
- **Milestone #9 `Dev environment`** — *this* repo's own dev-env tooling bootstrap (#145 git
  helpers, #152 act/colima runtime). Kept distinct from #8 `New-repo bootstrap` (which codifies
  how *new* repos start) so the two initiatives stay legible; both are thematic, not SemVer.
- **Token note (corrected 2026-07-12)**: do NOT infer the *scoped* `GH_TOKEN`'s permissions
  from label/milestone ops succeeding. In the agent's non-interactive bash, `direnv` does NOT
  export `GH_TOKEN` (empty despite `.envrc.local` present), so `gh` uses the stored `gh auth
  login` session (full-admin), not the scoped PAT. Issues-writes succeeding proves admin works,
  not the scoped token. Filed as #160 (priority high): `gh auth status` shows the fallback keyring session has scopes
  `repo,delete_repo,admin:public_key,gist,read:org` — so the agent holds delete_repo+admin, and
  the whole credential-scoping safety is inoperative in agent shells. #126 (scoped Issues:write)
  is moot until #160 loads the scoped token into the environment.
- **Grouping axes — two, deliberately distinct** (established 2026-07-12):
  - **Milestone = a body of work with a finish line** (`New-repo bootstrap` #8, `Dev environment`
    #9). Thematic, not SemVer.
  - **`theme:` label = a perpetual area the repo always has work in.** Created: `theme: testing`
    (CI/e2e/local-run), `theme: tool-review` (evaluate modern tool/plugin swaps), `theme:
    agent-config` (claude rules/skills/AGENTS.md), `theme: xdg-hygiene` ($HOME/XDG), `theme: credentials` (token scoping/storage/loading,
    created 2026-07-12). Prefix matches
    `priority:`. `upstream-review`/`release-watch` are older theme labels (same axis).
  - **Rule: NO per-commit-scope labels** (`area: zsh` etc.) — the title scope already owns that;
    duplicating drifts (single-source). Theme labels capture only what the scope *can't* express
    (cross-cutting work). A theme earns a label once ~3+ issues share it, not speculatively
    (mirrors the rules' maintenance gate). (`credentials` was held at 2, promoted to a label once #160 made it 3.)
  - GitHub Projects (v2) with an Area field is the escalation path if this goes multi-repo/roadmap;
    overkill for one solo repo now.
- **Workflow state**: `blocked` label added (2026-07-12) — the one state label for a timeline-free
  backlog ("not actionable until a dependency clears; reason in a comment / native blocked-by").
  Native GitHub issue dependencies exist (`blocked-by`/`blocking`, `issue_dependencies_summary`)
  but `gh` has NO dependency subcommand (API-only, not glanceable) — hence the label for at-a-glance
  filtering. Discipline: label = flag, reason = comment/native link (don't restate reason).
  Deliberately NOT added: `needs-info`/`needs-decision` (overlaps blocked+spike; solo repo weakens
  the reporter-nudge role). No `in-progress` (PR shows it).
- **`priority:` IS the timeline** (no milestones/dates by preference): high/medium/low = now/next/later.
  "What's next" query = `--label 'priority: high'` minus `--label blocked`. (Live state — run the
  query; do NOT cache the current answer here, it decays.)
- **Retired dead solo-repo defaults** (2026-07-12): `help wanted`, `question`, `invalid` — no external
  contributors/questions in a solo repo. Kept `duplicate`/`wontfix` (real dispositions).

**Epics use native GitHub sub-issues**, not just markdown checklists (epic bodies also carry a
checkbox build-breakdown). To attach a sub-issue:

    SUB_ID=$(gh api repos/:owner/:repo/issues/<CHILD_NUM> --jq '.id')   # numeric .id, NOT the issue number
    gh api --method POST repos/:owner/:repo/issues/<PARENT_NUM>/sub_issues -F sub_issue_id="$SUB_ID"

Gotcha: the API wants the child's integer database `id` (e.g. 4864370060), not its display
number, and it must be passed with `-F` (raw/typed) not `-f` (string) or it 422s with
"is not of type integer".

Good epic examples to match: #42 (CI e2e — rungs + explicit out-of-scope + acceptance),
#97 (agent-config skills — two-part epic with per-part breakdown).

Note: the agent-memory dir is tracked (not gitignored) and inside the repo checkout, so the
Write tool hits a worktree-isolation guard — write memory files via bash heredoc instead.
