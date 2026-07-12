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
