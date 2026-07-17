# 22. OpenTofu with R2-backed encrypted state for repos-as-code

Date: 2026-07-17

## Status

Accepted

## Context

Epic #273 moves repo creation and GitHub governance to code — `github_repository`,
`github_repository_ruleset`, `github_issue_label`, `github_actions_secret` —
with the copier templates keeping ownership of working-tree files. Spike #274
gated all implementation on four forks: tool (OpenTofu vs Terraform), config
structure (single config vs Terragrunt), state backend, and how already-existing
repos get adopted.

The binding constraint is secret-in-state: the provider docs state verbatim that
`github_actions_secret`'s value is sensitive-marked but _not_ hidden from state
files, and the planned RELEASE_PAT flows through that resource — so
encryption-at-rest for state is a requirement, not a preference. The scale is
one personal account with ~12 repos, one state, one operator.

Facts verified 2026-07-17: OpenTofu v1.12.4 (Terraform still BUSL-1.1);
`integrations/github` 6.13.0, served identically by the OpenTofu registry;
client-side state/plan encryption is OpenTofu-only (GA since 1.7); native S3
lockfile locking since OpenTofu 1.10 rides on conditional `PutObject`
(`If-None-Match`), which Cloudflare R2 honors and Backblaze B2 rejects (501,
hashicorp/terraform#37143); HCP Terraform's legacy free tier reached
end-of-life 2026-03-31 and OpenTofu is unsupported there in both directions.

All four decisions were validated by the spike's throwaway run (2026-07-17):
encrypted `for_each` import of two existing private repos, state migrated to
R2 and confirmed ciphertext at rest, lock contention producing a 412 on the
second concurrent plan with lockfile cleanup after, and a create-then-destroy
of a real test repo through the elevated credential.

## Decision

1. **OpenTofu** (current 1.12.x line), installed via Homebrew. Its client-side
   encryption is the only OSS answer to the secret-in-state constraint;
   nothing Terraform-only matters at this scale.
2. **Single config, `for_each` over a repos data map** — one codebase, config
   as data. No Terragrunt.
3. **State backend: Cloudflare R2** (S3-compatible, free tier, zero egress)
   with `use_lockfile = true` for native locking, plus **client-side
   encryption** (`aes_gcm` + PBKDF2 passphrase) supplied via the
   `TF_ENCRYPTION` env var with `enforced = true` for both state and plan —
   the passphrase never enters a tracked file. R2's S3 credentials derive
   from the R2 API token (access key ID = token ID; secret = SHA-256 of the
   full token value including its prefix); token and passphrase live in
   `.envrc.local` per the repo's credential model (ADR-0007). The backend
   block needs the standard non-AWS flags (`region = "auto"`, `use_path_style`,
   the `skip_*` set including `skip_s3_checksum`).
4. **Adopt existing repos with `for_each` import blocks** over the same repos
   map — declarative, one sweep, resource config hand-written (config
   generation doesn't support `for_each` imports, and the resources are
   `for_each` anyway).

Secrets pass through the provider's plaintext `value`; the encrypted state is
the protection. Auth stays two-tier per ADR-0007: the routine scoped token is
enough to plan (it read private repos fine), mutations use the elevated
credential — a fine-grained PAT with Administration + Secrets + Issues +
Metadata covers everything, no classic PAT needed.

## Alternatives considered

- **Terraform** — BUSL-1.1 since 1.6, and no client-side state encryption in
  OSS; that gap alone decides it given secret-in-state. No Terraform-only
  feature (Stacks, HCP integrations) applies here.
- **Terragrunt** — 1.0 (2026-03) with first-class OpenTofu support, but its
  niche is unchanged: DRY orchestration across many envs/accounts/units. One
  state and ~12 repos never touches that; a second codebase layer is pure
  overhead.
- **HCP Terraform free tier** — rejected on three 2026 facts: legacy free plan
  EOL'd 2026-03-31 (post-IBM paywall trend), OpenTofu unsupported by both
  sides (only a state-only/local-execution mode works, unsupported), and
  client-side encryption is incompatible with the `cloud` block (the platform
  parses state for RUM billing), so encryption would regress to trusting the
  server.
- **Backblaze B2** — free, but its S3 API returns 501 on `If-None-Match`, so
  native locking silently never engages (hashicorp/terraform#37143, still
  unfixed mid-2026). Lockless state was judged a real gap even solo.
- **AWS S3** — fully supported, least boilerplate, DynamoDB no longer needed —
  but no permanent free tier since 2025, and it adds an AWS account + IAM
  surface to maintain for pennies of monthly spend R2 doesn't charge.
- **Scalr free tier** — the one managed backend with explicit OpenTofu support
  (50 runs/mo free), but a TACOS platform is more machinery than a solo
  10-repo config needs, and client-side encryption is equally inapplicable.
- **Pre-sealed secrets via libsodium `encrypted_value`** — keeps plaintext out
  of state entirely, but adds an out-of-band sealing step to every rotation;
  encrypted state already covers the threat, so simplicity won.

## Consequences

Phase 1 (MVP TF inside dotfiles, #273) is unblocked with provider, auth,
backend, locking, encryption, and import all proven end to end. Costs and
tripwires: encrypted state is OpenTofu-only — decrypt before any move back to
Terraform; losing the PBKDF2 passphrase makes state unrecoverable, though
every managed resource re-imports, so the true blast radius is a re-import
sweep; enabling encryption on already-written plaintext state requires the
one-time `fallback` block dance; `TF_ENCRYPTION` and the R2 token load via
direnv, which only fires in the repo directory — running `tofu` elsewhere
silently loses them (the spike hit exactly this as a signature mismatch).
Provider edges to carry into Phase 1: imported `github_actions_secret` leaves
its value unpopulated in state, and `github_repository_ruleset` on private
repos still needs GitHub Pro (ADR-0017) — most current repos are private.
Rejected paths stay revisitable: Terragrunt if env/account count ever grows,
S3 if an AWS footprint appears anyway.
