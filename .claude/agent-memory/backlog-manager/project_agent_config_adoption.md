---
name: project-agent-config-adoption
description: Agent-config mechanisms mined from an external showcase (epic #298) — the borrow-filter to reapply when the user surfaces another external setup
metadata:
  type: project
---

Epic #298 adopted three *mechanisms* from `diet103/claude-code-infrastructure-showcase`
(progressive-disclosure skill convention #299, the plan-reviewer subagent #300, a minimal
activation-nudge spike #301) — details on the epic and children.

**Deliberately REJECTED (don't re-litigate):** the showcase's heavy hook infra — vector
embeddings, multi-LLM providers, session-doc indexing, metrics, PreToolUse blocking guards. Too
many moving parts for a solo machine-global setup, violates simplicity-first; the showcase
itself ships skill-activation disabled by default. Also skipped: its app-specific dev-guideline
skills and the "agents" that are really one-shot analyses (our bar keeps those as skills).

**The reusable filter:** showcase = per-repo/single-app; ours = machine-global/cross-repo/
vendor-neutral. Borrow mechanisms made repo-agnostic, never app content or heavy runtime infra.
Apply the same filter to the next external claude setup the user surfaces.

**Diminishing returns — expect mostly-reject, hunt the one genuine gap.** Epic #379's six
external-setup mines (ECC, ponytail, self-learning-skills, codex-plugin-cc, rtk, and han #477)
increasingly restate principles this setup already holds, sometimes *less* well. han (#477) was
the clearest case: three of its four named mechanisms rejected because ours already covered them,
one (flowchart skill-vs-agent test) rejected as strictly worse than ours. Enter a new mine
assuming most mechanisms are already-covered; the value is the single real gap, if any. Two
recurring landing lessons: (1) the skill-vs-agent boundary lives in the **README Skills section**
(memory + delegation + isolation), not the #299/#389 authoring conventions — check there before
accepting any "we don't gate the skill/agent line" premise; (2) mine the *pattern*, reject the
*tool* — e.g. danger/danger-js's companion-file "changed X not Y" rule was worth stealing (→ #493)
but Danger itself (Node runtime + bot) was not, same mechanism-yes/runtime-no filter.

**Spun off:** the reviewer vision grew into automation epic #302 (advisory LLM-in-CI; planner
pipeline where backlog-manager grooms and flags plan-review). The pipeline labels landed via
#305 — live set per `gh label list`, conventions in [[gh-conventions]].
