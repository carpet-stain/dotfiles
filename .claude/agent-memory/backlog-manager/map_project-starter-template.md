---
name: map-project-starter-template
description: Cross-repo map entry — carpet-stain/project-starter-template's backlog facts live in its own memory store
metadata:
  type: reference
---

- Repo: `carpet-stain/project-starter-template`
- Memory store: `.claude/agent-memory/backlog-manager/`
- Hook: copier templates (git-flow governance base + language overlays) extracted from dotfiles; ADR-0028 owns the why.
- Checkout hint (non-portable — probe before trusting; a wrong value means *unknown*, never "no checkout"): `~/code/project-starter-template`
