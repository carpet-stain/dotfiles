# 28. Extract copier templates to project-starter-template

Date: 2026-07-18

## Status

Accepted

## Context

`git-flow/` (the governance base) and `python/` (the language overlay) — the
two copier templates ADR-0020 and ADR-0021 designed — lived in dotfiles
because they started there, not because dotfiles is where a repo-scaffolding
toolkit belongs. Dotfiles' subject is one workstation's config; the templates
are a general-purpose tool for standing up _other_ governed repos, with their
own lint/CI/tooling story (#310) that has nothing to do with zsh, nvim, or
Ghostty. Carrying them here meant dotfiles' own PR history, commit-scope
vocabulary, and lint matrix carried a concern that belongs to a different
audience — the same shape of problem ADR-0024 already solved for the
Terraform/OpenTofu config, which moved to `carpet-stain/infra`.

`carpet-stain/infra`'s `repos.tf` (the repos-as-code model ADR-0024's move
established) made creating a new dedicated repo for this a routine, governed
operation rather than a one-off manual `gh repo create` — the same mechanism
that stood up `infra` itself now stood up the templates' new home too.

## Decision

Extract `git-flow/` and `python/` to a new dedicated repo,
`carpet-stain/project-starter-template`, created via `carpet-stain/infra`'s
`repos.tf` (dogfooding the same repos-as-code path other managed repos use).
The new repo is bootstrapped _with its own git-flow base_ — the repo that
ships the governance template is itself governed by it, same dogfood
principle ADR-0024 used for `infra`.

Sequenced as its own epic (#309) with three children: establish
render-then-lint tooling for the templates in dotfiles first, so it moved
already proven (#310); stand up the repo and move the templates + tooling in
(#311); remove them from dotfiles and repoint every reference (#312, this
change). Moved with a provenance note in `project-starter-template`'s own
move commit, not history-preserving subtree/filter-repo surgery —
`git-filter-repo` wasn't installed and the templates' own commit history was
small enough that a note pointing back at dotfiles (issue and PR numbers,
stable across this repo's own rebase-merges — a specific commit SHA
wouldn't be) covers it.

ADR-0020's layered-template design and ADR-0021's no-`copier update` decision
are unchanged by this move — they're decisions about how the templates work,
not where they live. `scripts/py-new.sh` and `scripts/retrofit-governance.sh`
(dotfiles-only convenience wrappers hardcoded to `~/.config/dotfiles/{git-flow,python}`)
are removed rather than repointed at the new repo's path: hardcoding another
repo's clone location is the same kind of machine-specific coupling XDG/
Configuration-Is-Code already reject for `$HOME` itself, and a wrapper for
the new repo's own templates is that repo's call to make, not dotfiles'.

Folds in #262 (declared commit-scope list had drifted from actual usage):
`python` leaves with the templates; `zellij` drops for zero commits in the
last 100 (stale); `claude` — the single most-used scope by far and
previously undeclared — plus `github`, `ci`, `release`, `adr`, `linux`,
`docs`, `deploy`, and `ghostty` (a real top-level directory missing from the
list even before this) are added.

## Alternatives considered

- **Keep the templates in dotfiles, just document the drift better** —
  rejected: doesn't address the actual problem (dotfiles' PR history and
  lint matrix carrying a concern with a different audience), just describes
  it more accurately.
- **Repoint `py-new`/`retrofit-governance.sh` at the new repo's path instead
  of removing them** — rejected: requires assuming `project-starter-template`
  is cloned at a specific local path, the exact kind of machine-specific
  assumption this repo's own XDG discipline exists to avoid. If a convenience
  wrapper is wanted, it belongs in `project-starter-template` itself.
- **History-preserving move (`git filter-repo` / subtree)** — not available
  (`git-filter-repo` isn't installed) and not clearly worth installing for a
  young, small history; a provenance note pointing at the exact dotfiles SHA
  is the documented fallback (#312's own text allows it).

## Consequences

Dotfiles becomes config-only for this concern: no `git-flow/`, `python/`,
`py-new`, or `retrofit-governance.sh`. New repos scaffold from
`carpet-stain/project-starter-template` directly (see its own README).
`AGENTS.md`'s commit-scope list and `git/committemplate` both carry the
recomputed set. Full history for the templates prior to this move lives in
dotfiles' own `git log` up to the commit that closes #312 (this change), not
in `project-starter-template`. If a `py-new`-equivalent convenience wrapper
is wanted again, it's a `project-starter-template` issue, not a dotfiles one.
