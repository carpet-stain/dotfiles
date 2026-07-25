---
name: project-python-starter
description: Python starter template (epic #129) — extracted to project-starter-template; ADR-0014 is the decision record
metadata:
  type: project
---

Epic #129 codified a reproducible packaged Python 3 starter (uv+ruff+pyright+pytest+lefthook+CI)
as a copier template. **The durable decision record is ADR-0014** — stack, alternatives, and
rationale live there, not here.

The template itself moved to `carpet-stain/project-starter-template` via epic #309 — see
[[project-gitflow-starter]] for that extraction's record. Dotfiles no longer carries a `python`
commit scope or a `py-new` wrapper.
