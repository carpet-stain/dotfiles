---
name: project-python-starter
description: Epic #129 — codify a reproducible packaged Python 3 starter (uv+ruff+pyright+pytest+lefthook+CI) via copier; decisions and rationale
metadata:
  type: project
---

**Epic #129** (`feat(python):`, enhancement + epic, priority: medium) — one-command bootstrap of a
new Python 3 project in this dotfiles repo, so new repos start deployment-ready. **Spike #130**
(sub-issue) prototypes + validates the toolchain before codifying. `~/code/golden-ratio` is the
live example of the gap and the first backfill/acceptance target.

**Decided stack (finalized 2026-07-11 with the user):**
- **uv** — package manager/env/lock; `.python-version` pinned to **latest stable** at init.
- **packaged src-layout** — `src/<pkg>/`, hatchling `[build-system]`, installable/importable
  (chosen over scripts-only: superset, clean pytest imports).
- **ruff** — lint + format; config explicit in `pyproject.toml` starting from ruff defaults.
- **pyright** — type checker. Chosen *because it matches nvim* (see constraint); mypy rejected
  (no LSP → editor/CI divergence); ty is the long-term watch but preview/pre-1.0, not a gate yet
  (nvim-lspconfig already ships a `ty` config, so it's a one-line swap later); basedpyright is a
  drop-in superset if stricter wanted.
- **pytest** — modern config (`-ra`, `--strict-markers`, `--strict-config`).
- **lefthook** — hooks call `uv run <tool>`: ruff check+format on pre-commit stage, pyright on
  pre-push stage.
- **GitHub Actions CI** — one job: setup-uv → uv sync → ruff check → ruff format --check →
  pyright → pytest.

**Key design decisions (the *why*, don't re-litigate):**
- **All config is committed files**, even when equal to a tool default (user's explicit ask;
  Configuration-Is-Code).
- **lefthook over pre-commit framework**: for a uv project, hooks call `uv run <tool>` so tool
  versions come from `uv.lock` — one source of truth, no second pinned copy to drift. pre-commit's
  per-hook env management is redundant once uv owns a locked dev env. Also matches the dotfiles
  repo's own lefthook use and the user's muscle memory. Trade-off accepted: lose the pre-commit
  hook ecosystem + pre-commit.ci bot (irrelevant for personal repos).
- **Hooks vs CI split**: type-check + pytest need the installed dep graph. lefthook runs
  `uv run ruff` on pre-commit (fast) and `uv run pyright` on pre-push; CI is the full gate.
- **Mechanism = copier** — only option with an update path (`copier update` re-applies template
  changes to existing repos), which the user wants. Copier templates the files; a post-gen task
  runs `uv python pin` + `uv sync`. This subsumes `uv init`.
- **nvim compat is the load-bearing constraint**: whatever CI enforces must be the binary the
  editor runs. nvim = pyright + ruff (verify against `nvim/lua/plugins/mason-tools.lua` +
  `lazyvim.plugins.extras.lang.python`, both can change).

**Scope boundary learned:** as backlog-manager I do NOT edit application/config files (e.g.
`macos/Brewfile`) or generate the prototype — those go through the repo's branch→PR dev flow.
"Add uv to Brewfile" is captured as the first task on #129, not done from this seat.

Introduces a new `python` commit scope. Debian: uv ships via its own installer, not apt — check
`linux/deploy.sh` if the toolchain must exist there.
