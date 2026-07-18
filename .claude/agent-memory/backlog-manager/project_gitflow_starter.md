---
name: project-gitflow-starter
description: Epic #136 (CLOSED) + follow-on #309 (CLOSED 2026-07-18) — portable git/GitHub workflow + repo-governance bootstrap, extracted to project-starter-template
metadata:
  type: project
---

**CLOSED.** Epic #136 codified a portable git/GitHub governance bootstrap (PR guards, branch
protection, release automation, labels, scoped token) as two copier templates — `git-flow/` (the
language-agnostic base) and `python/` (the language overlay), sharing the copier decision in
#130. Follow-on epic #309 then extracted both out of dotfiles into their own repo,
`carpet-stain/project-starter-template`, so dotfiles becomes config-only for this concern —
executed via #310 (lint tooling, proven in dotfiles first), #311 (stand up the repo + move the
templates in, split into project-starter-template#1/#2/#3), and #312 (remove from dotfiles,
repoint every reference, fold in the #262 commit-scope recompute). **The durable decision record
is dotfiles' ADR-0028** — read that for the why, not this file; this entry only holds findings
that outlive the epic and would matter again if a similar extraction happens.

**Load-bearing finding — `/compose-agents` only ports prose, by design.** Its
`claude/skills/compose-agents/SKILL.md` keeps `Write` out of `allowed-tools`; it drafts/proposes
AGENTS.md and nothing else, reading pr-guards/cliff/lefthook to describe them but wiring zero
enforcement. Moving governance via `/compose-agents` alone is impossible without breaking its
prose-only, propose-don't-write design — the enforcement/settings/labels needed a separate
scaffolder (the copier templates).

**Four layers of the governance apparatus (only prose ports via compose-agents):**

1. Prose — AGENTS.md git sections → compose-agents.
2. Tracked enforcement files — workflows, `cliff.toml`, `lefthook.yml`, `.envrc*`,
   `git/{committemplate,attributes,config,ignore}`, `dependabot.yml` → needed the copier
   scaffolder.
3. Repo settings (not files) — branch-protection ruleset, rebase-merge-only → needs
   **Administration** API; routine scoped `GH_TOKEN` can't; as backlog-manager, do NOT run these.
   Superseded for repos.tf-managed repos: `carpet-stain/infra`'s `tofu apply` now provisions this
   automatically alongside repo creation (see below).
4. Issue management — label taxonomy + templates → needs labels-as-code + apply step. Same
   infra-supersedes-manual pattern as layer 3.

**Two couplings that would recur in any similar extraction:** (a) the branch-protection ruleset
must require the *exact* check names pr-guards.yml emits (`single commit`, `conventional
commit`) or bad merges slip through; (b) a repo's actual model (e.g. short-lived branch →
squash-to-one → rebase-merge) may not match git.md's documented default — compose-agents can't
instantiate prose it wasn't told to fabricate; making a non-default model portable requires
promoting it to a first-class rule in git.md/github.md first (judgment/rules-content work,
propose before writing).

**Real gotcha hit during the #311 bootstrap, now recorded in project-starter-template#1's closing
comment and flagged for a dotfiles/project-starter-template docs fix:** once repo creation routes
through `carpet-stain/infra`'s `repos.tf`, branch protection is active *before* the first commit
exists — a direct push of the first commit is rejected (GH013). Worked around via the runbook's
own branch-rename contingency (push to a temp branch name, then `gh api .../branches/<b>/rename
-f new_name=main`), not by forcing the push or routing through a PR requiring a human merge.

**`carpet-stain/infra`'s `tofu apply` provisions labels *and* branch protection together with
repo creation** for every repo in `local.repos` — not just creation. Don't assume a
freshly-`local.repos`-added repo still needs manual `apply-labels.sh`/
`bootstrap-branch-protection.sh`; check live state first (`gh api repos/<repo>/rulesets`,
`gh label list --repo <repo>`).
