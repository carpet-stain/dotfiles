# Python project starter

Copier template for bootstrapping a packaged, reproducibility-gated Python 3
project (#129). Decisions and rationale live on the issue; this is the
mechanism.

This is a **language overlay on the git-flow governance base** (`../git-flow`),
not a standalone template — `py-new` applies git-flow first, then layers this on
top. The layers own disjoint files (ADR-0020 in this repo's `docs/adr/`): the
overlay ships its own CI workflow (`test.yml`), its lefthook jobs
(`lefthook-lang.yml`, overwriting the base's empty stub), and its just verbs
(`justfile.lang`, picked up by the base justfile's `import?`). Everything the
base ships — `lint.yml`, PR guards, ADR guard, the PR template, `docs/adr/`
scaffolding, the credential pattern — comes through untouched; only
`.gitignore` and the pointer-pure `README.md` replace the base's copies.

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

The templates write no `.copier-answers` file, so there is no `copier update`
path — scaffold once, then evolve the repo directly (ADR-0021 in this repo's
`docs/adr/`).

## What it produces

- Packaged src-layout (`src/<package>/`, hatchling build backend)
- `pyproject.toml`: `dev` dependency group (ruff, pyright, pytest), explicit
  `[tool.ruff]` and `[tool.pytest.ini_options]`
- `.python-version` pinned to the latest stable interpreter uv resolves at
  generation time; `requires-python` patched to match
- `lefthook-lang.yml`: `ruff check` + `ruff format --check` on commit and
  `pyright` on push, tagged `lang` — via `uv run`, so tool versions come from
  `uv.lock`. Merged with the base's jobs by the base lefthook.yml's `extends`
- `.github/workflows/test.yml`: `uv sync --locked`, the `lang` lefthook slice
  (`uvx lefthook run pre-commit --all-files --tag lang` — no Homebrew), then
  pyright + pytest. The base's `lint.yml` runs the base slice separately
- `justfile.lang`: `test`, `typecheck`, `format` — the base's `import?` picks
  it up next to `lint`/`adr`
