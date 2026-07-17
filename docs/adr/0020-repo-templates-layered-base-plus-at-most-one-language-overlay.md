# 20. Repo templates: layered base plus at most one language overlay, disjoint files via native composition

Date: 2026-07-17

## Status

Accepted

## Context

The repo-bootstrap tooling is two copier templates: `git-flow/` (the
language-agnostic governance base) and a language overlay (`python/` today,
with Go, Terraform, and Ansible foreseen) applied on top — at most one overlay
per repo, ever. Copier cannot merge files across templates, so any file both
layers ship collides and the overlay's copy wins.

The first reconciliation (#278/#279) settled the collision by making each
overlay's `ci.yml`, `lefthook.yml`, and `justfile` a **superset**: replaying
roughly 90 lines of base content (six lefthook jobs, the CI lint job, the
`lint`/`adr` verbs) and adding the language's jobs on top. That works, but it
puts N+1 copies of the base pipeline in this repo — hand-synced on every base
change, drift caught only by eyeballs — and every `copier update` of an
overlay re-asserts replayed base content against whatever the base update just
changed. The review question: is there a design where the layers stop sharing
files at all?

## Decision

Keep the layered model — one governance base plus at most one language
overlay — but give the layers **disjoint file ownership**, composed by each
tool's native mechanism instead of file-level replay:

- **CI**: separate workflow files. The base owns `lint.yml`; an overlay ships
  its own workflow (`test.yml`). GitHub composes workflows by directory, and
  required checks bind to job names, not filenames.
- **justfile**: the base owns the composition root — `import 'justfile.base'`
  plus `import? 'justfile.lang'` — and `justfile.base` with the `lint`/`adr`
  verbs. An overlay drops in `justfile.lang`; the optional import is silently
  absent until then.
- **lefthook**: the base owns the root `lefthook.yml` (`extends:
[lefthook-base.yml, lefthook-lang.yml]`), the base jobs in
  `lefthook-base.yml` tagged `base`, and an empty `lefthook-lang.yml` stub. An
  overlay overwrites the stub with its jobs tagged `lang`.
- **CI/local split via tags**: locally, unfiltered `lefthook run pre-commit`
  runs every layer's jobs on commit. In CI, the base's `lint.yml` runs
  `just lint --tag base` with the base toolchain; the overlay's `test.yml`
  runs its `lang` slice with its own toolchain (python: lefthook from PyPI
  via `uvx`, no Homebrew). This dissolves the coupling that forced the
  original single `ci.yml` (#269): the base lint job never needs the language
  toolchain.

Each mechanism was verified empirically before adopting: `import?` no-ops
when absent, lefthook `extends` accepts an empty stub, `--tag` selects
exactly the tagged slice, and lefthook installs from PyPI.

Overlays become pure additions. The remaining shared files: `.gitignore`
(git has no include mechanism for tracked ignores — the overlay replays the
base's single `.envrc.local` entry) and the seeded `README.md` (pointer-pure
and structurally identical in both layers, so the overwrite is harmless).

## Alternatives considered

- **Overlay-as-superset** (the #279 model this supersedes) — replays ~90
  lines of base pipeline per overlay, hand-synced on every base change with
  nothing mechanical catching drift, multiplied by each future overlay;
  `copier update` of base and overlay fight over the same files.
- **One template with a `language` choice question** — zero replay, but the
  per-language separation is lost: overlays stop being self-contained
  directories, shared files accumulate Jinja conditionals, and base and
  overlay can no longer version/update independently. Rejected; native
  composition achieves zero replay without those costs.
- **Separate templates sharing Jinja include fragments via symlinks** —
  fragile copier-loader hackery across template roots; rejected outright.
- **Other scaffolders** (cookiecutter/cruft, projen, GitHub template repos)
  — none match copier's update-with-3-way-merge story, and projen's
  continuous file ownership conflicts with the apply-additively,
  operator-resolves retrofit model (#282).

## Consequences

- Adding an overlay is a pure addition: its workflow, `lefthook-lang.yml`,
  `justfile.lang`, and whole-files. No base content to replay, no sync duty.
- Base and overlay `copier update` independently and can no longer conflict
  on each other's files.
- `just --list` spans two files and lefthook resolves one `extends` hop —
  the acceptable cost of the seams.
- Version floors: `just` ≥ 1.33 (`import?`), any current lefthook
  (`extends`, tags). Both far below the versions in use.
- The `base`/`lang` tag names are part of the contract between the base's
  workflow and every overlay's — renaming them is a breaking change across
  all overlays.
