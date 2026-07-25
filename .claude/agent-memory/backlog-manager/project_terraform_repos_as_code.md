---
name: project-terraform-repos-as-code
description: Repos-as-code with OpenTofu (epic #273) — decision pointers and the standing grooming calls; continuation lives in carpet-stain/infra
metadata:
  type: project
---

Repos-as-code shipped via epic #273 and moved out: **all further TF/governance work belongs in
`carpet-stain/infra`'s backlog, never dotfiles** — dotfiles has no `terraform/` anymore. The
durable records: ADR-0022 (OpenTofu + R2-encrypted state — the stack decision and its
alternatives), ADR-0023 (trivy over checkov), ADR-0024 (descoped the copier TF overlay — no
fleet of TF repos is coming), and infra's own founding ADR-0002. Implementation edges and
gotchas live on the epic's phase issues/PRs (#274/#292, #294/#295, #296) and infra's README.

**Why it exists:** user wanted repos-as-code; asked whether Terragrunt's model still holds
(answer: no at this scale — single config, `for_each` over a repos map).

**Boundary (load-bearing, recorded in project-starter-template's git-flow README):** copier owns
working-tree files; Terraform owns GitHub **API-level** resources only (`github_repository`,
ruleset, labels, actions secrets).

**Standing grooming calls:** `terraform` title scope exists (introduced with the epic);
epic-and-children got `priority: low`, milestone New-repo bootstrap; sub-issue mechanics in
[[gh-conventions]]. See [[reference-infra-repo]] for the tofu-apply-provisions-everything
lesson.
