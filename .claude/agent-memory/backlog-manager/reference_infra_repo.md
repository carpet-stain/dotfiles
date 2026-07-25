---
name: reference-infra-repo
description: carpet-stain/infra — sibling repo governing GitHub account-as-code; has its own backlog-manager memory store, read before grooming cross-repo work
metadata:
  type: reference
---

`carpet-stain/infra` (`~/code/infra`, public) manages GitHub account governance via OpenTofu:
repo settings, the canonical label set (`repos.tf`'s `local.labels`, shared with dotfiles via
`setproduct(local.repos, local.labels)`), and branch-protection rulesets for every repo in
`local.repos` (`dotfiles`, `infra`, `project-starter-template`). Labels are terraform-governed
there — never `gh label create` directly, propose via `repos.tf`.

**It keeps its own project-scoped backlog-manager memory**, at
`~/code/infra/.claude/agent-memory/backlog-manager/` (repo_overview.md, label_taxonomy.md,
open_work.md, dotfiles_repo.md, backlog_conventions.md, MEMORY.md) — read those when grooming
infra, don't assume dotfiles' conventions transfer (infra has no milestones, no `theme:
xdg-hygiene`-style dotfiles-only themes, and epics use native sub-issues with zero markdown
checklist duplication).

**Cross-repo dependency web — CLOSED out 2026-07-18.** dotfiles#309 (epic: extract copier
templates to `project-starter-template`) → #310/#311 → #312 all shipped and closed; durable
record is dotfiles' ADR-0028. infra#14 (added `project-starter-template` to `local.repos`) and
infra#15 (synced `needs-plan-review`/`plan-approved` into `local.labels`) both closed the same
`tofu apply`. **Still open:** dotfiles#331 (retire `scripts/apply-labels.sh`, now that infra#15
landed) — no longer blocked, just not yet actioned.

**Risk found 2026-07-18, filed as infra#74 on 2026-07-24:** infra's `.claude/agent-memory/`
dir is **untracked** — never committed to `origin/main` (`git log --all -- .claude` is empty),
unlike dotfiles' where the same dir is tracked via `git memory-pr` (ADR-0027). A `git clean -fd`
or careless branch switch there loses it silently. infra#74 is the fix: `git memory-pr` is
machine-global tooling (deployed by dotfiles' own deploy scripts, not dotfiles-specific — works
in any repo with a `.claude/agent-memory/backlog-manager/` dir), so the fix is just running it
there for the first time, plus adding a `reference-dotfiles-repo`-equivalent file so the pointer
goes both directions. Check infra#74's state before re-flagging this. Also, infra's local
checkout was on a stale `migrate-terraform` branch with upstream gone (already merged/deleted) as
of 2026-07-18 — `gh issue`/`gh api` calls are unaffected (they hit the API, not local files), but
anyone editing infra's tracked files locally should `git fetch && git switch main` first.

**2026-07-18: infra#14 + infra#15 closed same session (batch `tofu apply`).** Confirmed via
`repos.tf` that `github_repository_ruleset.this` and `github_issue_label.this` are both
`for_each = local.repos` — a single apply provisions repo creation, the full label set, *and*
branch protection together for every managed repo, not just creation. Don't assume a freshly
`local.repos`-added repo still needs manual `apply-labels.sh`/`bootstrap-branch-protection.sh` —
check live state first (`gh api repos/<repo>/rulesets`, `gh label list --repo <repo>`) before
recommending those scripts; see [[project-gitflow-starter]] for the concrete case
(`project-starter-template`) and the runbook-step implications.

`repos.tf`'s `project-starter-template` entry was found mis-scoped (described it as Python-only,
topics without `git-flow`) — filed as **infra#20**, gated on
`carpet-stain/project-starter-template#3` (the real README) landing first as the accurate
wording source. #3 has since merged; infra#20 is actionable now.

**2026-07-24: Bitwarden Secrets Manager account-budget question spans both repos.** infra#71
(closed via PR #72) documented the consumer-facing Bitwarden structure — and in doing so
surfaced that the free tier's 3-Machine-Account cap (ADR-0008) is fully spent. That fed directly
into dotfiles#377 (dotfiles' own `GH_TOKEN` migration — likely resolvable for free via the
already-vended token, pending one scope-gap check: the vended token has no `Actions` permission,
dotfiles' current PAT does) and dotfiles#399/#400 (a new LLM-key secret with no existing Project
to live in). Filed **infra#73** to make the actual account-budget call (consolidate two of the
three existing Machine Accounts, share the `vended-tokens` Project, or pay for a higher tier) —
whichever way it resolves, dotfiles#377's Non-goals needs a follow-up edit (see the comment
thread there) and dotfiles#399/#400 inherit whatever Project the LLM key lands in. Read infra#73
before touching either dotfiles credentials issue.

**2026-07-24: infra#75 filed — `deal-finder` new-repo creation.** New personal project (secondhand
PC-parts marketplace monitor, see [[project-deal-finder]]); no `import` block needed since it's a
genuinely new repo, just a `local.repos` map entry. Confirmed via `repos.tf`/README: a brand-new
entry still needs the fresh-repo default-label collision handled the same way as every prior
apply (import-block the colliding six, hand-delete the three GitHub-default strays). Not mine to
`tofu apply` — elevated, infra's own domain.
