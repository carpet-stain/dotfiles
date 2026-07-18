---
name: project-python-starter
description: Epic #129 — CLOSED; python starter template extracted to project-starter-template (2026-07-18, folded into #309/#312)
metadata:
  type: project
---

**CLOSED.** Codified a reproducible packaged Python 3 starter (uv+ruff+pyright+pytest+lefthook+CI)
as a copier template. The durable decision record is dotfiles' **ADR-0014** — stack, alternatives
considered, and rationale all live there, not here.

The template itself (`python/`, formerly in this repo) moved to
`carpet-stain/project-starter-template` via epic #309/#312 — see [[project-gitflow-starter]] for
that extraction's own record. Dotfiles no longer carries a `python` commit scope or a `py-new`
wrapper.
