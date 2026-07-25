---
name: reference-infra-repo
description: carpet-stain/infra — sibling GitHub-governance repo with its own backlog-manager memory; read it before grooming cross-repo work
metadata:
  type: reference
---

`carpet-stain/infra` (`~/code/infra`, public) manages GitHub account governance via OpenTofu:
repo settings, the canonical label set, and branch-protection rulesets for every repo in
`repos.tf`'s `local.repos`. **Labels are terraform-governed — never `gh label create`; propose
via `repos.tf`.** All repo creation routes through `local.repos` + `tofu apply` (elevated,
infra's domain — never mine to run).

**It keeps its own backlog-manager memory** at `~/code/infra/.claude/agent-memory/
backlog-manager/` — read those files when grooming infra; dotfiles' conventions don't transfer
(different milestones/themes). Cross-repo residency rules are #421's scope.

**Operating lesson:** a single `tofu apply` provisions repo creation, the full label set, *and*
branch protection together for every managed repo. Don't assume a freshly-added repo still
needs the manual label/protection scripts — check live state first (`gh api
repos/<repo>/rulesets`, `gh label list --repo <repo>`).

**Cross-repo pointers** (live status on the issues, not here):

- infra#20 — `project-starter-template` entry mis-scoped in `repos.tf`.
- infra#73 — the Bitwarden Machine-Account budget decision lives there; read it before touching
  dotfiles credential issues (#377/#399/#400) — they inherit it.
- infra#74 — infra's memory dir was untracked; the fix is running `git memory-pr` there
  (machine-global tooling, works in any repo with the memory dir).
- infra#75 — deal-finder repo creation (see [[project-deal-finder]]).
