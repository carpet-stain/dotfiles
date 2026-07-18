---
name: project-terraform-repos-as-code
description: Epic #273 (OPEN) — move repo creation/governance to OpenTofu as a language overlay; Phase 0 spike + conventions rule DONE (ADR-0022), Phase 1 MVP is #294
metadata:
  type: project
---

**Epic #273 (OPEN, priority low, milestone New-repo bootstrap)** — manage repo creation + GitHub
governance as code with OpenTofu. A **new language overlay** on the git-flow base, same pattern as the
Python starter [[project-gitflow-starter]] (#129).

**Why / origin:** user wants repos-as-code; hadn't used Terraform in ~5 years, liked the Terragrunt
"model in one repo, config in another" model and asked if it's still best (answer: no, at this scale).

**Boundary (load-bearing, from `git-flow/README.md`):** copier owns working-tree files; Terraform owns
GitHub **API-level** resources only — `github_repository`, `github_repository_ruleset`,
`github_issue_label`, `github_actions_secret`. Supersedes the "replace with a TF resource" notes in
`scripts/apply-labels.sh` + `scripts/bootstrap-branch-protection.sh`; turns runbook steps 1/3/4 into
`tofu apply`.

## Phasing + status

- **Phase 0 — decision spike #274: DONE.** Closed by merged PR #292, which added ADR-0022
  (`docs/adr/0022-opentofu-with-r2-backed-encrypted-state-for-repos-as-code.md`). Throwaway apply
  validated the whole loop end to end — evidence + gotchas in PR #292's journal comment.
- **Conventions rule #291: DONE.** Closed by merged PR #293 — `claude/rules/tools/terraform.md`
  (paths-gated, aligns with ADR-0022; `tenv` as version manager, write-`.tf`-not-`.tofu` caveat).
- **Phase 1 — MVP, TF inside dotfiles, one real repo end to end: #294 (OPEN, next up).** Done =
  `tofu apply` manages the repo cleanly — import-adopted, no spurious drift, plan converges to zero
  changes. Carried-forward edges live on the issue (see below).
- **Phase 2 — TF overlay tooling.** Copy the Python overlay's structure for TF: `tofu fmt -check`,
  `tflint`, a security scan, wired into lefthook + CI. **Old hard dependency now satisfied** — the
  Python overlay #129 and its refinement #236 are both CLOSED, so Phase 2 is unblocked structurally.
  **Still holds one TBD: the scanner pick** (trivy vs checkov) — input to that call is trivy's
  Feb–Mar 2026 supply-chain incident (GHSA-69fq-xp46-6x23). Not yet filed as an issue.
- **Phase 3 — move TF to its own repo,** created by that same TF (dogfood loop; keeps admin creds off
  dotfiles, preserving its scoped-token guarantee). Not yet filed.

## Decisions — SETTLED in ADR-0022 (were "leans", now chosen)

- **OpenTofu 1.12.x over Terraform** — open/MPL; native state encryption, required because
  `github_actions_secret`/RELEASE_PAT lands in state.
- **Single config, `for_each` over a repos data map — NOT Terragrunt.** Terragrunt's many-env/account
  niche is scale not present here.
- **State backend: Cloudflare R2** (bucket `tofu-state` exists) with `use_lockfile` native locking +
  OpenTofu client-side encryption (aes_gcm + PBKDF2 via `TF_ENCRYPTION`, enforced for state AND plan).
  Chosen over HCP free tier / other S3-compatible.
- **Adopt existing repos via `import` blocks.**

## Phase 1 carried-forward edges (from spike, on #294 + PR #292)

- Imported `github_actions_secret` leaves its value unpopulated in state — must not churn on plan.
- `github_repository_ruleset` on private repos needs GitHub Pro (403); most existing repos are private
  — scope the MVP around rulesets, don't block on them.
- R2 S3 creds derive from the R2 API token: access key ID = token ID; secret = SHA-256 of the full
  token value incl. the `cfut_` prefix.
- direnv only exports inside the repo dir ⇒ `tofu` must run from the repo; misuse fails as
  `SignatureDoesNotMatch`, not a missing-credential error.
- backend `endpoints` is a map argument.
- Credential/env wiring goes in `.envrc`/`.envrc.local` per ADR-0007; the `envrc-local-example-sync`
  lint gate means new vars must be listed in `.envrc.local.example`.

## Grooming judgment calls (standing)

`terraform` title scope introduced alongside the epic (like `python` was). Epic + all sub-issues
`priority: low`, milestone New-repo bootstrap. Sub-issues linked via GraphQL `addSubIssue`
(see [[gh-conventions]] for the mutation).
