# 24. no tf copier overlay - config moves to its own repo

Date: 2026-07-17

## Status

Accepted

## Context

Epic #273's original phasing assumed a fleet of future TF repos: Phase 2
would package the TF tooling as an `opentofu/` copier overlay mirroring the
Python starter (ADR-0020 lists Terraform among foreseen overlays), and
Phase 3 would move the config into a dedicated infra repo created by its
own TF. With Phase 1 merged (#294 — `terraform/` manages this repo with a
zero-drift plan), the premise got re-examined: the operator doesn't foresee
creating more TF repos. The overlay would be template machinery for users
that won't exist — the same scale argument that rejected Terragrunt in
ADR-0022. The dedicated repo, though, is a one-off with standing value
independent of any fleet.

## Decision

Scrap the copier overlay; keep the move. No `opentofu/` template ever —
the overlay's substance (fmt/lint/scan wiring) lands directly in whatever
repo hosts the config: dotfiles' lefthook + CI today (ADR-0023), the infra
repo's after the move. The TF config does move to its own dedicated repo —
created by this very TF (the dogfood proof of the creation path) — carrying
`terraform/`, the three lefthook jobs, the `.envrc` backend/encryption
wiring, and the elevated-apply workflow out of dotfiles. Because it's a
single repo rather than a template's output, it gets bootstrapped once via
the conventions rule's COMPOSE flow (claude/rules/tools/terraform.md), not
scaffolded from copier. ADR-0020's layered-template model stands for
Python; its "foreseen" overlay list was aspiration, not commitment.

Why the move survives the descope: account-governance config doesn't
belong permanently inside a public workstation-dotfiles repo — the infra
repo can be private (its plans and repos map describe every repo's
governance, including private ones), it owns the elevated-credential and
TF env surface so dotfiles carries none of it, and separation keeps both
repos' PR history about one thing.

## Alternatives considered

- **The `opentofu/` copier overlay (original Phase 2)** — fully designed
  (composition seams mapped: `justfile.lang`, `lefthook-lang.yml` with the
  `lang` tag, own SHA-pinned CI workflow, `tf-new.sh` driver, `[[ ]]`
  envops) but rejected before building: a template with no second consumer
  is maintenance without a user. Design notes preserved in epic #273's
  comment trail (2026-07-17) for revival if a fleet materializes.
- **Keeping TF in dotfiles permanently** — rejected: leaves account-wide
  governance data and the TF credential/env surface inside a public
  config repo whose subject is the workstation, and bloats its hook/CI
  matrix with a concern that has a natural home of its own.
- **Keeping the overlay open as "someday"** — rejected: a recorded plan
  nobody intends to execute misleads grooming and future agents; explicit
  descope keeps the epic honest.

## Consequences

Until the move, nothing changes day to day: `terraform/` and its hygiene
stay in dotfiles. The move becomes the epic's remaining milestone: TF
creates the new repo, the config + hooks + env wiring migrate, dotfiles
drops its TF-specific Brewfile/lefthook/CI entries, and the state backend
carries over untouched (state lives in R2, not in either repo). The
RELEASE_PAT/`github_actions_secret` increment can land before or after the
move. Revisit the overlay decision only if a real fleet of TF-managed
repos appears — revive from the recorded design rather than re-deriving.
