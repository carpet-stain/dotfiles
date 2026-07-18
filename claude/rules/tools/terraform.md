---
paths:
  - "**/*.tf"
  - "**/*.tofu"
  - "**/*.tfvars"
  - "**/*.tftest.hcl"
  - "**/.terraform.lock.hcl"
---

<!-- Terraform/OpenTofu idioms. Canonical source: my dotfiles. Language-level only — never a
     repo path, state bucket, org name, or branch. The paths: frontmatter is the gate: Claude
     Code loads this only when a TF file is read, structurally, no prose guard needed.
     Rationale: claude/README.md. -->

> ### GATE
>
> The `paths:` frontmatter is the gate — this file loads only when Claude reads a
> Terraform/OpenTofu file (`*.tf`/`*.tofu`/`*.tfvars`/tests/lockfile), in any repo. No prose
> guard needed.

> ### LOCAL-WINS
>
> If this repo has its own Terraform standards doc (e.g. docs/CODING.md), that doc is
> AUTHORITATIVE: treat this as baseline and prefer the repo's doc on conflict.

> ### COMPOSE — give a repo its own concrete Terraform doc
>
> Trigger: the human asks to scaffold, OR a TF repo lacks a standards doc and one is warranted.
> PROPOSE, don't create. Steps: (1) read this as baseline; (2) write a repo-local doc (e.g.
> docs/CODING.md) restating these with the repo's concrete nouns — tofu or terraform, the
> backend and how its state is encrypted, provider pins, linter/scanner config, module layout;
> (3) add to the repo's AGENTS.md that docs/CODING.md is authoritative over generic Terraform
> conventions (name no personal path); (4) after this the repo reads its own doc — don't
> re-distill.

# Terraform / OpenTofu Conventions

Baseline is the [OpenTofu style conventions](https://opentofu.org/docs/language/syntax/style/)
(mirroring HashiCorp's style guide), with
[Terraform: Up & Running](https://www.terraformupandrunning.com/) (Brikman, 3rd ed.) as the
idiom text — it predates the OpenTofu split; the mechanics transfer. Essentials: `fmt`
formatting is non-negotiable; `snake_case` names; name a resource for its role, never its type
(`github_repository.this`, not `.github_repo` — the type label already says what it is); `this`
for the only instance of a type in a module; singular resource names even under `for_each` —
the map provides the plurality; `locals` for any expression used twice; `for_each` over
`count` for collections (keyed addresses survive reordering; `count` is for the boolean
create-or-don't case only). Write `.tf`, not `.tofu`: the surrounding toolchain (tflint,
terraform-docs) parses only the shared extension, so the fork-specific one buys nothing and
silently drops files out of lint and docs coverage.

Design stance: **HCL is declarative configuration, not a programming language** — model
variation as data, not logic. A typed map fed to `for_each` beats chained conditionals,
nested-splat pyramids, and clever `flatten`/`merge` meta-programming; when an expression needs
a comment to parse, restructure the data instead. Config-as-data also keeps the change diff
where review wants it: editing an entry in a map, not editing resource logic. Structure: start
with a **flat root module** and extract a child module only at a real reuse boundary — a
module with one caller is abstraction without a boundary (Simplicity First); avoid module
nesting beyond one level. File layout by concern: `versions.tf` (core + provider
requirements), `variables.tf`, `main.tf` (splitting by resource area as it grows),
`outputs.tf`.

Version discipline: `required_version` on the core, `required_providers` with `~>` pessimistic
pins, and the committed `.terraform.lock.hcl` as the reproducibility gate — upgrades happen
deliberately via `init -upgrade` in their own diff, never as a side effect. Install and pin
the runtime itself with [tenv](https://github.com/tofuutils/tenv): it resolves the version
from the config's own `required_version` constraint (or an `.opentofu-version` file) and
verifies release signatures — the same honor-the-code's-pin behavior as Go's
`GOTOOLCHAIN=auto` or uv's pinned interpreters, so the version the config declares is the
version that runs. Vendor providers with `tofu providers mirror` when an environment needs
offline or supply-chain-pinned installs.

Interfaces are contracts: every variable and output carries a `type` and `description`;
`validation` blocks encode constraints the type system can't; `sensitive = true` on anything
secret-shaped; `nullable = false` unless null is genuinely meaningful. A module's variables
and outputs are its API — document them as such, and let terraform-docs generate the readable
reference from those declarations: generated docs are only as good as the types and
descriptions they're built from.

**State is a plaintext secret store.** Providers write attribute values into it verbatim —
`github_actions_secret` is the canonical trap: the value is sensitive-_marked_ but not hidden
from state. So: remote backend with locking; encryption at rest is required, not optional, the
moment any resource writes a secret into state (OpenTofu's client-side `encryption` block with
`enforced = true` covers state and plan files; keep key material in the environment, never in
config). Never commit state, plan files, or `.terraform/` — gitignore all three from day one.

Refactor declaratively: `moved {}`, `removed {}`, and `import {}` blocks (with `for_each` for
adopting existing infrastructure in one sweep) — all reviewable in the plan before they touch
anything. `state mv`/`state rm` surgery is the last resort, not the habit.

Make the mechanizable parts tooling-enforced: `fmt -check` and `validate` as the floor,
`tflint` for lintable rules (the bundled terraform ruleset's `recommended` preset is the
baseline; note tflint has no official OpenTofu support — fine on `.tf`, broken on `.tofu` and
some OpenTofu-only syntax), a config security scanner (trivy — the successor to tfsec — or
checkov) for the misconfiguration classes engineering-practices.md's Security By Default
names, and native `tofu test` (`.tftest.hcl`) where a module's contract deserves proof.
Judgment parts — resource naming, module boundaries, what becomes data vs config — stay a
matter of review.

## OpenTofu-first

Terraform relicensed to BUSL in 2023; OpenTofu is the MPL fork under Linux Foundation
governance, drop-in for this layer and the provider ecosystem. Default to OpenTofu for new
work. Know the one-way doors before leaning on divergent features: state written with OpenTofu
encryption (and state touched by OpenTofu ≥1.10 generally) is not readable by Terraform —
fine as a deliberate commitment, wrong as an accident. The per-repo tool choice, backend, and
encryption scheme are repo decisions — record them in the repo's ADR and its COMPOSE'd doc,
not here.

## DRY without Terragrunt

At single-account/single-environment scale, one configuration with `for_each` over a data map
_is_ the DRY story — config and code separate cleanly inside one codebase. Terragrunt earns
its keep orchestrating many state files across environments/accounts with shared remote-state
wiring; below that scale it's a second codebase layer with no boundary to justify it. Revisit
at genuine multi-env/multi-account scale, not before.
