---
name: gh-conventions
description: Backlog conventions and gh mechanics for the carpet-stain/dotfiles repo (labels, epics, sub-issues, milestones)
metadata:
  type: reference
---

Repo `carpet-stain/dotfiles` backlog conventions (verify with `gh label list` — labels evolve):

- **Titles**: Conventional-Commit style `type(scope): imperative desc`. Scopes in use:
  `zsh, zellij, git, nvim, macos, theme, python` (AGENTS.md's own list omits `zellij`/`python`
  despite real commit history using both — the issue-form templates' scope comment
  (`.github/ISSUE_TEMPLATE/spike.yml`) is the more current source if the two ever disagree).
  Scopeless `feat:`/`ci:`/`chore:` titles are also common, especially for epics. New scopes are
  fine — flag on first use.
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
- **`release-watch` issues get triaged with a priority label too** (codified 2026-07-24 from
  precedent — #194-196 already did this, #20-22/#60 predate the discipline and were left as-is).
  Default `priority: low` (someday/version-bump review). `agent-ready` only if the verification
  step is non-interactive/mechanical — most aren't: a rendering/TUI fix (#194's color-parsing
  bug) can be agent-verified via grep/diff, but a "does this look right in a Zellij popup" or
  "does tree-view ordering change" check (#383, #384) needs a human eyeballing a GUI/TUI, per
  AGENTS.md's own carve-out for that class of change.
- **Grooming sweeps should spot-check labels lagging their own convention, not just untriaged
  issues** (found 2026-07-24): #377/#388 were the two live `theme: credentials` issues but
  neither carried the label (it was created *for* this pair, per the entry above, but never
  backfilled onto them); #393 was `architecture`-labeled but never got `needs-plan-review`. Both
  are the kind of gap that "no priority label = untriaged" doesn't catch — worth an explicit pass
  over open issues' labels against the taxonomy each sweep, not just checking for missing
  priority.
- **A referenced issue can be deleted out from under a cross-reference** (found 2026-07-24):
  epic #379 listed #386 as one of five children; #386 closed normally (reject-with-salvage, mined
  into #394) but was later deleted from GitHub entirely (`gh api .../issues/386` → 410 "This
  issue was deleted", not just closed — `gh issue view` fails to resolve it at all). The epic body
  still named it as a live child. Rewrote #379's Children section to point at #394 (where the
  outcome actually lives) instead of the dead number. Worth checking any epic/issue with old
  cross-references for this during a sweep — closed is normal and fine to leave alone, a 410 is
  the thing to catch and repoint.

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

**2026-07-24 grooming finding — CI-shares-the-local-lint-command means format jobs can't switch to
`--write` without breaking CI as a gate.** In this repo (and identically in project-starter-template
and any git-flow-scaffolded repo), `ci.yml`'s lint job runs the exact same command as `just lint`
(`lefthook run pre-commit --all-files`) — there's no separate CI-only `--check` variant. A
formatter job (`md-format` = `prettier --check`) can't be switched to `--write`+`stage_fixed` for
local auto-fix convenience, because `--write` always exits 0: CI would rewrite files in its
throwaway checkout and report green regardless of whether the actual pushed commit was formatted,
silently breaking the format gate. The fix that keeps both properties (local convenience + CI
still a real gate) is a separate, unhooked recipe (`just format`) — reach-by-hand, same pattern as
`cliff-preview`/`act`/`bootstrap-branch-protection.sh` — not a change to the job lefthook and CI
share. Filed as dotfiles#405/#406 (reorder md-format before markdownlint; add the `format` recipe)
+ ported to project-starter-template#19/#20 (blocked on the dotfiles pair landing first, per #310's
"prove lint tooling in dotfiles before porting" precedent). This reasoning will recur for any
future lefthook job that's tempted to add `--write`/`stage_fixed` — check whether CI invokes the
identical command before assuming it's safe.

**Also from that pass — MD013/MD007 in `.markdownlint-cli2.yaml`:** checked live before opining
(Verify, Don't Trust) — `markdownlint-cli2 "claude/rules/**/*.md"` reports zero MD013 violations
today (an earlier byte-length awk scan looked like violations but was counting UTF-8 em-dash bytes,
not markdownlint's character count), so MD013 is a working, currently-honored guardrail, not dead
weight — recommended keeping it rather than disabling outright absent a concrete friction example.
MD007's `indent` default is already `2` (confirmed in markdownlint's own rule source, `params.config
.indent || 2`) — explicitly setting `indent: 2` in config would be a no-op, so no action taken.

**2026-07-24, second grooming pass — reviewed .editorconfig/.yamlfmt/actrc/justfile/lefthook.yml
for gaps.** Concrete findings, filed as #407-#410 (all `priority: low`):
- **`justfile` had zero lint/format enforcement** — every other config type in this repo has one,
  the justfile didn't. `just --fmt --check` (stable since 1.57.0, no `--unstable` needed) already
  passes clean against the current file — zero-cost to add. #407.
- **`shellcheck`/`shfmt` job order is lint-then-format**, the one holdout against the
  format-before-lint convention #405 establishes for markdown (lua/toml pairs already had this
  right). #408.
- **`.editorconfig` is real, enforced config for stylua/prettier-covered files** (verified
  empirically: stylua's `--no-editorconfig` flag exists specifically to disable this, and a
  2-space-vs-tab test file inside the repo tree picks up `indent_size = 2` with zero `.stylua.toml`
  present) — but nothing enforces it for files no formatter covers at all (zsh/*, git/config,
  ssh/config). `editorconfig-checker` (Homebrew, confirmed available) closes that gap. #410.
- **`yaml-format`'s glob excludes `.github/workflows/*.yml`/`ISSUE_TEMPLATE/*.yml`/`nvim/vim.yml`**
  — not documented as deliberate, but widening it isn't a clean flip: `yamlfmt -lint` run by hand
  against `release-prepare.yml` wants to collapse an intentionally-wrapped `>-` folded scalar onto
  one line. Filed as a spike (#409), not a straight fix, because the real risk needed evidence
  (found it) before committing to the change.
- **No changes to `actrc`**: every workflow's `runs-on` is `ubuntu-latest`, matching the single
  existing pin — nothing uncovered.
