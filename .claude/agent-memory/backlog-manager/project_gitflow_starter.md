---
name: project-gitflow-starter
description: Epic #136 — codify a portable git/GitHub workflow + repo-governance bootstrap; four-layer model and the compose-agents boundary
metadata:
  type: project
---

**Epic #136** (`feat(git):`, enhancement + epic, priority: medium) — make a new GitHub repo reach
the full git workflow (PR guards, branch protection, release automation, labels, scoped token)
from one bootstrap. **Spike #137** (sub-issue) decides the mechanism. Sibling to **#129** (Python
starter): #136 is the language-agnostic *governance base*, #129 the *language overlay*; they
share the copier decision in **#130** — one base template, not two.

**Load-bearing finding — `/compose-agents` only ports prose, by design.** Its
`claude/skills/compose-agents/SKILL.md` keeps `Write` out of `allowed-tools`; it drafts/proposes
AGENTS.md and nothing else. It *reads* pr-guards/cliff/lefthook to describe them but wires zero
enforcement. So "move gitflows via /compose-agents" is impossible as-is without breaking its
prose-only, propose-don't-write design. The enforcement/settings/labels need a separate scaffolder.

**Four layers of the git apparatus (only layer 1 ports today):**
1. Prose — AGENTS.md git sections → compose-agents (done).
2. Tracked enforcement files — `.github/workflows/{pr-guards,release-prepare,release-publish}.yml`,
   `cliff.toml`, `lefthook.yml`, `.envrc(.local.example)`, `git/{committemplate,attributes,config,
   ignore}`, `dependabot.yml` → needs a scaffolder (copier, shared base w/ #129).
3. Repo settings (NOT files) — branch-protection ruleset requiring the PR-guard checks,
   rebase-merge-only, block direct push to main → needs **Administration** API; routine scoped
   `GH_TOKEN` can't; run `env -u GH_TOKEN gh ...`. As backlog-manager I do NOT run these.
4. Issue management — label taxonomy + templates + milestones → needs labels-as-code + apply step.

**Two couplings:** (a) the ruleset (3) must require the *exact* check names pr-guards.yml (2)
emits (`single commit`, `conventional commit`) or bad merges slip through; (b) this repo's actual
model — short-lived branch → squash-to-one → **rebase-merge** — is NOT git.md's documented default,
so compose-agents can't instantiate its prose (detect.sh flags it heuristically, skill told not to
fabricate). Making it portable requires *promoting the rebase model to a first-class rule* in
git.md/github.md — judgment/rules-content work, propose before writing.

**detect.sh already models the porting facts** (branch_model, version_scheme, release automation,
pre_commit_tool, credential_pattern) — good foundation for the scaffolder's placeholders.

**Follow-on epic #309** (feat(git), OPEN) extracts the git-flow base + Python overlay out of
dotfiles into a new `project-starter-template` repo, so dotfiles becomes config-only. Scope is
**git-flow + python only, NOT terraform** — corrected 2026-07-18 after [[project-terraform-repos-as-code]]
(#273) closed: TF left dotfiles directly for the sibling repo `carpet-stain/infra`, never routing
through `project-starter-template`. #309's children: #310 (template lint/format tooling), #311
(stand up the new repo), #312 (remove the templates from dotfiles, also resolves the commit-scope
drift in #262).

**#311's step 1 dependency shape changed 2026-07-18.** Repo creation for every managed repo now
routes through `carpet-stain/infra`'s `repos.tf` `locals.repos` map, not a manual `gh repo
create` — #311's original step 1 text was stale the moment #273 closed. Filed
**carpet-stain/infra#14** (adds the `project-starter-template` entry) as the real unblock, edited
#311 to point at it, and applied dotfiles' `blocked` label to #311 with a comment explaining why
(real current blocker, not speculative — remove once infra#14 is applied and the repo exists).

**Label drift found + fixed the same session:** dotfiles' live `needs-plan-review` /
`plan-approved` labels (applied manually via `scripts/apply-labels.sh` after infra's `repos.tf`
was last written) were never captured in infra's `local.labels` — filed
**carpet-stain/infra#15** to sync them in, with the import-blocks gotcha documented on the issue
(they exist live on dotfiles already, so a bare `tofu apply` after adding them to `local.labels`
would try to create-and-409 on the dotfiles side; needs `import` blocks for those two instances
first). Filed **dotfiles#331** to retire `scripts/labels.json` + `scripts/apply-labels.sh`
(AGENTS.md + `git-flow/README.md`'s bootstrap runbook both reference it) once infra#15 lands —
explicitly blocked on infra#15 so a newly-created repo never loses its only label-bootstrap path
mid-transition. `scripts/bootstrap-branch-protection.sh` has the same eventual fate (superseded by
infra's `github_repository_ruleset`) but that's not filed yet — flagged as a follow-up to ask
about, not decided.
