# Python project starter

Copier template for bootstrapping a packaged, reproducibility-gated Python 3
project (#129). Decisions and rationale live on the issue; this is the
mechanism.

## Use

```sh
py-new <new-project-dir>
```

`py-new` (see `scripts/py-new.sh`) wraps `uvx copier copy --trust`. `--trust`
isn't optional: it's what lets the post-generation task run at all (pins the
interpreter via `uv python pin`, syncs the lock via `uv sync`, `git init`s,
installs the git hooks via `lefthook install`) -- without it, copier silently
skips every one of those and leaves a project with no lock file and no hooks.
Answers project name, package name, description, and author along the way.

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
- `lefthook.yml`: `ruff check` + `ruff format --check` on commit, `pyright`
  on push — both via `uv run`, so tool versions come from `uv.lock`
- `.github/workflows/ci.yml`: one job — `uv sync --locked`, then
  ruff check, ruff format check, pyright, pytest
