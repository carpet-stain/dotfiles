# 14. Python starter stack: uv + copier + ruff + pyright + pytest + lefthook

Date: 2026-07-12

## Status

Accepted

## Context

Every new Python 3 project re-paid the reproducibility layer by hand (#129).
`~/code/golden-ratio` was the live example of the gap: a sound package skeleton,
but loose `>=` deps, no lock file, a hand-rolled `.venv`, no pinned interpreter,
ruff lint-only, no type gate, no git hooks, no CI (#129). A hard constraint:
`nvim/` already type-checks Python with pyright and lints/formats with ruff
(`lazyvim_python_lsp = "pyright"`, Mason
`ensure_installed = { pyright, ruff }`), so the starter had to enforce the same
binaries or the editor and CI would diverge (#129). Config had to land as
committed files, not tool ambient defaults (Configuration-Is-Code, #129). The
template also had to be consumable in new repos and updatable later as the
template evolves (#129, #130). Spike #130 de-risked the wiring end-to-end before
codifying. This record is backfilled: the repo only adopted ADRs afterward
(af8b28e9, Jul 13), a day after the bootstrap command landed (deba2441, Jul 12).

## Decision

One command scaffolds a packaged, reproducibility-gated Python 3 project. Stack:
uv (env/lock/pin, `uv.lock` committed, `.python-version` pinned to the latest
stable interpreter via `uv python pin`); packaged src-layout with the hatchling
build backend; ruff for lint+format; pyright for type checking; pytest; lefthook
git hooks; a one-job GitHub Actions CI. Delivered as a copier template
(`python/`) driven by `py-new <path>` (wraps `uvx copier copy --trust`). Hooks
and CI call tools via `uv run`, so versions come from `uv.lock` — one source of
truth, no editor-vs-CI drift (#129). Split by stage: `ruff check` +
`ruff format` on pre-commit, pyright on pre-push, all four gates in CI (#129).

## Alternatives considered

- **mypy (type checker)** — no language server, so nvim could only run it as a
  save-time linter and the editor and CI would type-check differently; pyright
  matches what nvim already runs (#129).
- **ty (Astral type checker)** — right family (uv+ruff), fast, and the pinned
  `nvim-lspconfig` already ships a ty config, but preview/pre-1.0, not fit for a
  CI gate yet; watched as a one-line swap when it stabilizes (#129).
- **pre-commit framework (over lefthook)** — manages its own per-hook tool
  environments, pinning a second copy of ruff/pyright that drifts from the
  uv-locked ones the editor and CI use; lefthook runs commands directly, so
  hooks call `uv run <tool>` against the project's locked env — no second pinned
  copy (#129).
- **uv_build backend (over hatchling)** — backend choice was left open going
  into the spike; hatchling was picked during #130 validation
  (`uv init --app --package --build-backend hatch`) and confirmed working
  end-to-end (#130).
- **Update-less template mechanisms (cookiecutter, GitHub template repo)** —
  copier was chosen as the only option with an update path (`copier update`
  re-applies template changes to already-generated repos via
  `.copier-answers.yml`), the "consume in new repos and update later"
  requirement (#129, #130). The specific update-less alternatives copier's
  update path beat are inferred — #129/#130 name copier's advantage, not the
  rejected tools.

## Consequences

A new Python project bootstraps deployment-ready from `py-new <path>` alone;
golden-ratio was re-bootstrapped and its gaps closed (#129). `--trust` is
mandatory in the wrapper — without it copier silently skips the post-gen tasks
(`uv python pin`, `uv sync`, `git init`, `lefthook install`) and leaves a
project with no lock file and no hooks (python/README.md). Enforced tooling now
matches nvim (ruff + pyright); the same commands run in the editor, in lefthook,
and in CI, so nothing drifts (#129). Adds a `python` commit scope (#129).
macOS-only for now: `uv` added to the macOS Brewfile; on Debian uv ships via its
own installer, not apt, so `linux/deploy.sh` needs the toolchain confirmed
separately (#129). Revisit the type checker when ty stabilizes — a one-line swap
from pyright (#129). basedpyright is a drop-in superset if stricter/inlay
features are ever wanted (#129).

(provenance: partial — the specific update-less alternatives (cookiecutter,
GitHub template repo) are inferred; #129/#130 name only copier's update-path
advantage, not the rejected tools.)
