# Python project starter

Copier template for bootstrapping a packaged, reproducibility-gated Python 3
project (#129). Decisions and rationale live on the issue; this is the
mechanism.

This is a **language overlay on the git-flow governance base** (`../git-flow`),
not a standalone template — `py-new` applies git-flow first, then layers this on
top. The overlay's `ci.yml`, `lefthook.yml`, and `justfile` supersede the base's
colliding copies, carrying the base governance forward and adding the Python
jobs; its `.gitignore` and `README.md` likewise replace the base's copies.
Everything else the base ships — PR guards, ADR guard, the PR template,
`docs/adr/` scaffolding, the credential pattern — comes through untouched.

## Use

```sh
py-new <new-project-dir>
```

`py-new` (see `scripts/py-new.sh`) applies two copier templates with `--trust`:
the git-flow base, then this overlay. `--trust` isn't optional: it's what lets
the post-generation tasks run at all (pins the interpreter via `uv python pin`,
syncs the lock via `uv sync`, `git init`s, installs the git hooks via
`lefthook install`) -- without it, copier silently skips every one of those and
leaves a project with no lock file and no hooks. You answer the base's questions
(owner, repo, protected branch, release automation) first, then this overlay's
(project name, package name, description, author).

## Update an existing generated project

```sh
uvx copier update --trust
```

Run from inside the generated project (it reads `.copier-answers.yml`, which
the initial `copier copy` writes automatically). `--trust` applies here too --
tasks re-run on update the same as on the initial copy.

## What it produces

- Packaged src-layout (`src/<package>/`, hatchling build backend)
- `pyproject.toml`: `dev` dependency group (ruff, pyright, pytest), explicit
  `[tool.ruff]` and `[tool.pytest.ini_options]`
- `.python-version` pinned to the latest stable interpreter uv resolves at
  generation time; `requires-python` patched to match
- `lefthook.yml`: superset of the base's jobs (actionlint, markdownlint,
  prettier, yamlfmt, envrc-sync) plus `ruff check` + `ruff format --check` on
  commit and `pyright` on push — the ruff/pyright jobs run via `uv run`, so tool
  versions come from `uv.lock`
- `.github/workflows/ci.yml`: a `lint` job (base linters + ruff via
  `just lint`) and a `test` job (`uv sync --locked`, then pyright + pytest)
- `justfile`: base `lint`/`adr` verbs plus `test`, `typecheck`, `format`
