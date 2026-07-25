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

**Spun off:** the reviewer vision grew into automation epic #302 (advisory LLM-in-CI; planner
pipeline where backlog-manager grooms and flags plan-review). The pipeline labels landed via
#305 — live set per `gh label list`, conventions in [[gh-conventions]].
