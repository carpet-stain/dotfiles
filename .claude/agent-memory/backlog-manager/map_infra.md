---
name: map-infra
description: Cross-repo map entry — carpet-stain/infra's backlog facts live in its own memory store
metadata:
  type: reference
---

- Repo: `carpet-stain/infra`
- Memory store: `.claude/agent-memory/backlog-manager/` (tracked on its `origin/main`)
- Hook: GitHub account governance as OpenTofu — repo settings, canonical labels (terraform-governed, never `gh label create`), branch protection; read its store before grooming there.
- Checkout hint (non-portable — probe before trusting; a wrong value means *unknown*, never "no checkout"): `~/code/infra`
