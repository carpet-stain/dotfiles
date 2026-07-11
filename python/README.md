# Python project starter

Copier template for bootstrapping a packaged, reproducibility-gated Python 3
project (#129). Decisions and rationale live on the issue; this is the
mechanism.

## Use

```sh
uvx copier copy ~/.config/dotfiles/python <new-project-dir>
```

Answers project name, package name, description, and author, then a
post-generation task pins the interpreter (`uv python pin`), syncs the lock
(`uv sync`), and installs the git hooks (`lefthook install`).

## Update an existing generated project

```sh
uvx copier update
```

Run from inside the generated project (it reads `.copier-answers.yml`, which
the initial `copier copy` writes automatically).

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
