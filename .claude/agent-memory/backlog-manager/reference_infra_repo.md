---
name: reference-infra-repo
description: carpet-stain/infra — sibling repo governing GitHub account-as-code; has its own backlog-manager memory store, read before grooming cross-repo work
metadata:
  type: reference
---

`carpet-stain/infra` (`~/code/infra`, public) manages GitHub account governance via OpenTofu:
repo settings, the canonical label set (`repos.tf`'s `local.labels`, shared with dotfiles via
`setproduct(local.repos, local.labels)`), and branch-protection rulesets for every repo in
`local.repos` (today: `dotfiles`, `infra`; `project-starter-template` pending infra#14). Labels
are terraform-governed there — never `gh label create` directly, propose via `repos.tf`.

**It keeps its own project-scoped backlog-manager memory**, at
`~/code/infra/.claude/agent-memory/backlog-manager/` (repo_overview.md, label_taxonomy.md,
open_work.md, dotfiles_repo.md, backlog_conventions.md, MEMORY.md) — read those when grooming
infra, don't assume dotfiles' conventions transfer (infra has no milestones, no `theme:
xdg-hygiene`-style dotfiles-only themes, and epics use native sub-issues with zero markdown
checklist duplication).

**Cross-repo dependency web (verified consistent 2026-07-18):** dotfiles#309 (epic: extract
copier templates to `project-starter-template`) → #311 (stand up the repo, blocked on
infra#14) → #312 (reconcile dotfiles after). dotfiles#331 (retire `apply-labels.sh`) blocked on
infra#15 (sync `needs-plan-review`/`plan-approved` into `local.labels`). All four cross-links
verified bidirectional and non-stale via `gh issue list --search` on both repos — no dangling or
conflicting references found. Both infra#14 and infra#15 correctly reference back to their
dotfiles counterparts in their own bodies.

**Risk found, not mine to fix (flagged to the user):** infra's `.claude/agent-memory/` dir is
**untracked** — never committed to `origin/main` (`git log --all -- .claude` is empty), unlike
dotfiles' where the same dir is tracked. A `git clean -fd` or careless branch switch there loses
it silently. Also, infra's local checkout was on a stale `migrate-terraform` branch with upstream
gone (already merged/deleted) as of 2026-07-18 — `gh issue`/`gh api` calls are unaffected (they
hit the API, not local files), but anyone editing infra's tracked files locally should
`git fetch && git switch main` first.

**2026-07-18: infra#14 + infra#15 closed same session (batch `tofu apply`).** Confirmed via
`repos.tf` that `github_repository_ruleset.this` and `github_issue_label.this` are both
`for_each = local.repos` — a single apply provisions repo creation, the full label set, *and*
branch protection together for every managed repo, not just creation. Don't assume a freshly
`local.repos`-added repo still needs manual `apply-labels.sh`/`bootstrap-branch-protection.sh` —
check live state first (`gh api repos/<repo>/rulesets`, `gh label list --repo <repo>`) before
recommending those scripts; see [[project-gitflow-starter]] for the concrete case
(`project-starter-template`) and the runbook-step implications.

Also found live: `repos.tf`'s `project-starter-template` entry describes it as Python-only
("Starter template for new Python projects...", topics without `git-flow`), mismatched with
dotfiles#309's actual git-flow-base+python-overlay scope. Flagged to the user, not filed — small
infra PR to fix description/topics once the real README exists.
