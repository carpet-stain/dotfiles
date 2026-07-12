---
name: feedback-single-source-of-truth
description: User strongly prefers one enforced source of truth over duplicated prose/config — his lens for judging proposed docs/config
metadata:
  type: feedback
---

The user consistently favors a **single enforced source of truth** and dislikes duplicating a
spec that a tool/config already owns.

**Why:** ties to their own rules — Configuration-Is-Code (the rule lives in the versioned config a
tool reads) and work-through-human-toolchains (the agent hits the same gate a human does, so the
gate is authoritative, not restated prose). Duplication drifts.

**Mental model (user's words, crystallized):** AGENTS.md is the *signpost*, config is the
*spec* — "do X, in this order, for this reason; details in `<file>`." Only enforceable detail
moves to config; the why + workflow shape stay in the doc (config can't hold them).

The generic habit this implies — point at enforced config, don't restate it — is now in
`backlog-manager.md`'s "What a good issue looks like" (portable, applies in any repo). Watch for
the over-correction, though: the cut is *restate → point*, NOT *enforced → delete* — keep the
*why*, the workflow shape, and fuller guidance where the feedback loop is slow/downstream (CI-only,
branch protection). AGENTS.md is also a human doc, so pointer-form serves both; deletion strips
human value.

**Applies at two layers.** Outward (AGENTS.md, #140): signpost/spec — point at the enforcing
config. Inward (the abstract `claude/rules/**`, #142): you can't point at a config that doesn't
exist pre-composition, so the move is *de-duplication* — one rule file owns a mechanic, others
point to it (github.md ↔ git.md model); each enforceable spec lives once as its COMPOSE template.
Both layers: de-dup + tighten, NEVER prune-to-zero (deleting a spec from the rules breaks compose).

**Instances seen (2026-07-11):** ruff config must be an explicit committed file, not implicit
defaults (#129); lefthook hooks call `uv run <tool>` so versions come from `uv.lock`, one source,
no second pinned copy (#129); compose-agents/audit-rules should point at enforced config instead of
restating it in AGENTS.md (#140). See [[project-gitflow-starter]], [[project-python-starter]].
