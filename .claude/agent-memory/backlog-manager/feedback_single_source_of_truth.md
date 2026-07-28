---
name: feedback-single-source-of-truth
description: Nuances of the user's single-source-of-truth lens that the rules don't carry — over-correction warning, inward layer, instance pointers
metadata:
  type: feedback
---

The core preference — one enforced source of truth, signpost-vs-spec, point-don't-restate — is
now **encoded in the always-loaded rules** (`documentation.md`'s "One home per fact",
`design-principles.md`'s Configuration-Is-Code) and AGENTS.md's realization sections. This memory
predates that graduation (2026-07-12 vs rule landing 2026-07-14) and keeps only what the rules
don't carry:

**Over-correction warning:** the cut is *restate → point*, NOT *enforced → delete*. Keep the
*why*, the workflow shape, and fuller guidance where the feedback loop is slow/downstream
(CI-only checks, branch protection). AGENTS.md is also a human doc — pointer-form serves both;
deletion strips human value.

**Inward layer** (the abstract `claude/rules/**`, #142): you can't point at a config that doesn't
exist pre-composition, so the move there is *de-duplication* — one rule file owns a mechanic,
others point to it (github.md ↔ git.md model). De-dup + tighten, NEVER prune-to-zero: deleting a
spec from the rules breaks compose.

**Why:** duplication drifts; the agent hits the same gate a human does, so the gate is
authoritative, not restated prose.

**How to apply:** judge proposed docs/config/issues through this lens. Instances: ruff config as
an explicit committed file (#129); lefthook calling `uv run <tool>` so `uv.lock` is the one
version source (#129); AGENTS.md pointing at enforced config (#140). See
[[project-gitflow-starter]], [[project-python-starter]].
