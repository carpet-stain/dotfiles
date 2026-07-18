# 21. Generated repos carry no copier answers file, so no copier update

Date: 2026-07-17

## Status

Accepted

Amends the copier-update consequence of
[20. Repo templates: layered base plus at most one language overlay](0020-repo-templates-layered-base-plus-at-most-one-language-overlay.md);
that ADR's disjoint-file decision stands unchanged. The templates this
decision concerns now live in
[`carpet-stain/project-starter-template`](https://github.com/carpet-stain/project-starter-template)
(ADR-0028); `retrofit-governance.sh` (referenced below) no longer exists in
this repo.

## Context

Both templates generated a `.copier-answers` file
(`.copier-answers.git-flow.yml` for the base, `.copier-answers.yml` for the
overlay) via a `[[ _copier_conf.answers_file ]].jinja` file. That file is
copier's sole enabler of `copier update`: it records the answers and the
template version so a later update can compute an incremental 3-way merge of
only the delta. ADR-0020 leaned on this ("base and overlay `copier update`
independently").

But the actual lifecycle doesn't use it. A repo is scaffolded **once** — either
`copier copy` onto an empty repo, or a one-time `retrofit-governance.sh`
git-merge onto a small existing repo — and evolved directly after that. A new
template convention is applied to an existing repo by editing it (or a wholesale
re-retrofit), never by `copier update`. So the answers file is dead metadata,
and its `_src_path` even bakes an absolute machine path into every repo.

## Decision

Neither template writes a `.copier-answers` file: the
`[[ _copier_conf.answers_file ]].jinja` files and the base's `_answers_file`
setting are removed. `copier copy` and `retrofit-governance.sh` remain the only
application paths; propagating a later template change into an existing repo is
a manual edit, or a fresh retrofit for a wholesale refresh.

copier is thus used purely as a one-shot generator. Its update-with-3-way-merge
advantage over cookiecutter — the reason it was chosen — is deliberately left
unused; it stays the generator because the retrofit path (#282) is built on
copier's rendering, and switching generators would buy nothing.

## Alternatives considered

- **Keep the answers file for an optional `copier update` path** — rejected:
  unused in the stated lifecycle, commits a machine-specific `_src_path`, and
  carries per-repo metadata for a capability that won't be exercised. Pointing
  `_src_path` at a Git URL to de-machine it still keeps unused metadata.
- **Drop copier entirely for a plain generator** (cookiecutter, or a script) —
  rejected: the retrofit path already depends on copier's rendering + tasks,
  and copier-as-generator is strictly fine; no reason to churn it.

## Consequences

- No delta-based updates. A base improvement reaches existing repos only by
  hand-editing them, or a re-retrofit that re-conflicts on every shared file
  (README, `.gitignore`) — acceptable because the fleet is small and each repo
  is bootstrapped once.
- Generated repos are cleaner — no copier metadata, no absolute paths.
- The retrofit script no longer preserves answers files; nothing else changes
  in it.
- Reversible: re-adding the `_copier_conf.answers_file` template file restores
  `copier update` for repos generated after that point.
