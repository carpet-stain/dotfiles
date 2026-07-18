# 23. trivy for Terraform misconfiguration scanning

Date: 2026-07-17

## Status

Accepted

## Context

The repos-as-code epic (#273) left the TF security scanner TBD — the
conventions rule (claude/rules/tools/terraform.md) names the class but not
the pick. With `terraform/` real and merged (#294), the candidates could be
compared on actual config instead of feature matrices. Bake-off on the live
config (2026-07-17): trivy found two issues in ~6s — GIT-0001 "repo is
public" (a false positive here: dotfiles is deliberately public) and
GIT-0003 "vulnerability alerts disabled" (real: the config didn't assert
`vulnerability_alerts`); checkov found only the same false positive in ~16s
and missed the real finding. tflint (0.64, recommended preset) is the
correctness/style lane either way and doesn't overlap.

Two 2026 ecosystem facts bear on the choice. trivy had a supply-chain
compromise in Feb–Mar 2026 (GHSA-69fq-xp46-6x23: malicious releases plus
hijacked `trivy-action` tags stealing CI secrets), so how it's consumed
matters as much as whether. And tflint left homebrew-core in May 2026 over
a license change (terraform-linters/tflint#2530) — it installs from
`terraform-linters/tap` now, recorded here because both tools ride the same
Brewfile/CI install path.

## Decision

trivy (`trivy config`), wired as a `tofu-scan` pre-commit job in
lefthook.yml next to `tofu-format` and `tofu-lint` (tflint), installed via
Homebrew in both macos/Brewfile and ci.yml's lint job — never via
`trivy-action` or floating release artifacts, which were the compromised
vectors. Findings are fixed or suppressed inline with a rationale comment
(`#trivy:ignore:GIT-0001` on the deliberately-public repos resource;
GIT-0003 fixed by asserting `vulnerability_alerts = true` for every managed
repo).

## Alternatives considered

- **checkov** — broader IaC policy catalog on paper, but on this config it
  was blind to the one real finding, ~3× slower, and drags a Python stack
  where trivy is a single Go binary. Nothing here needs its cross-resource
  graph checks.
- **tfsec** — formally deprecated; its checks migrated into trivy, which
  keeps the check-ID and ignore-comment compatibility.
- **terrascan** — archived upstream (2025), not a live option.
- **Skipping a scanner** (fmt + validate + tflint only) — those lanes don't
  cover misconfiguration classes at all; the bake-off's GIT-0003 catch is
  the concrete argument that the scanner earns its slot.

## Consequences

TF changes get the same shift-left treatment as every other language here:
three lang-specific pre-commit jobs, mirrored exactly in CI via the shared
`just lint` entry point. The supply-chain posture is a standing constraint,
not a one-time fix: trivy stays Homebrew-installed, and if a GitHub Action
ever replaces that, it gets pinned by commit SHA. tflint's tap dependency
is a small platform risk (a relicensed linter outside homebrew-core);
revisit the lint lane if its license tightens further. Trivy's blanket
repos-should-be-private check stays suppressed at the resource — visibility
is deliberate per-repo data in `terraform/repos.tf`, so new public repos
won't re-trigger it, and a wrongly-public repo won't be caught by trivy;
that review lives in the repos map diff instead.
