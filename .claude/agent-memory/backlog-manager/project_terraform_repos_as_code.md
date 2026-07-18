---
name: project-terraform-repos-as-code
description: Epic #273 (OPEN) — repos-as-code with OpenTofu; Phases 0-1 DONE, overlay SCRAPPED but the move to an own TF-created repo RETAINED (ADR-0024)
metadata:
  type: project
---

**Epic #273 (OPEN, priority low, milestone New-repo bootstrap)** — manage repo creation + GitHub
governance as code with OpenTofu, in dotfiles' `terraform/` until the planned move to a dedicated
TF-created repo. The original "language overlay like the Python starter
[[project-gitflow-starter]]" framing was **descoped 2026-07-17 (ADR-0024)** — no fleet of TF repos
is coming; the one-off infra repo bootstraps via terraform.md's COMPOSE flow instead.

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
- **Phase 1 — MVP: DONE.** #294 closed by merged PR #295 — `terraform/` manages the dotfiles repo
  (settings + 21 labels + protect-main ruleset), import-adopted, plan converges to zero. R2 backend +
  enforced client-side encryption live; env derived in `.envrc` from four `.envrc.local` secrets;
  tenv (Brewfile) pins the runtime from `required_version`; `just tofu` / `just tofu-apply` split
  scoped plan from elevated apply.
- **TF lint hygiene: PR #296** — `tofu-format`/`tofu-lint`(tflint)/`tofu-scan`(trivy) lefthook jobs +
  CI installs + Brewfile. **Scanner decided: trivy over checkov (ADR-0023)** — bake-off on the live
  config (trivy caught GIT-0003, checkov missed it, 3× faster); Homebrew-only consumption because of
  GHSA-69fq-xp46-6x23. tflint installs from `terraform-linters/tap` (left homebrew-core May 2026,
  license change).
- **Phase 2 (copier overlay): SCRAPPED — ADR-0024** (2026-07-17; epic comment preserves the mapped
  design for revival). Operator won't mint more TF repos; a template with no second consumer is
  maintenance without a user.
- **Phase 3 (move TF to its own repo): DONE 2026-07-18.** `carpet-stain/infra` (public — free plan
  means private repos get no rulesets, and dotfiles' governance data was already public) was created
  BY the TF config (dotfiles PR #306), bootstrapped with the git-flow base only, then the config
  migrated there (infra PR #4): root-level *.tf, labels + protect-main ruleset generalized to all
  managed repos via `moved` blocks, hand-filled overlay seams (justfile.lang, lefthook-lang.yml
  `lang` jobs, pinned-binary tofu.yml workflow), founding ADR-0002 restating the stack. dotfiles
  removal PR strips terraform/ + hooks + CI installs + `.envrc` wiring (Brewfile keeps
  tenv/tflint/trivy as machine tools). Gotchas recorded in infra's README: fresh repos are seeded
  with GitHub default labels (6 collide → temp import blocks; 3 strays deleted by hand).
- **Other remaining scope (incremental):** adopt more repos into the `repos.tf` map; manage
  `github_actions_secret`/RELEASE_PAT (fourth boundary resource) for release-automated repos.

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
