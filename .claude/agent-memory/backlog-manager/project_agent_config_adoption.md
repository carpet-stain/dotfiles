---
name: project-agent-config-adoption
description: Epic #298 (CLOSED 2026-07-18) — agent-config mechanisms borrowed from the diet103 infra showcase; all three children shipped, what we adopted and what we deliberately rejected
metadata:
  type: project
---

**Epic #298 (CLOSED 2026-07-18, was priority low)** — adopted three *mechanisms* from `diet103/claude-code-infrastructure-showcase`'s `.claude` setup, filtered through this repo's philosophy. All three children shipped, closing the epic:
- **#299** (docs, low, CLOSED) — progressive-disclosure + 500-line rule as a documented skill-authoring convention.
- **#300** (feat, medium, CLOSED — the standout) — a repo-agnostic, read-only plan/architecture-reviewer subagent (adversarial fresh-context review; the one showcase "agent" that can't be a skill because isolation is the point).
- **#301** (spike, low, CLOSED) — evaluated a *minimal* skill-activation nudge hook (trigger map + UserPromptSubmit reminder); shared #280's "is skill machinery worth it" lens.

**Deliberately REJECTED (don't re-litigate):** the showcase's heavy hook infra — vector embeddings, multi-LLM providers (gemini/openai/ollama), session-doc indexing, metrics, PreToolUse blocking guard. Too many moving parts for a solo machine-global setup, violates simplicity-first/minimal-infra, and the showcase itself ships skill-activation `disabled` by default. Also skipped: its app-specific backend/frontend dev-guideline skills (TS/Node/Prisma/Sentry — not portable), TS build hooks, and 6 of its 8 "agents" that are one-shot analyses our subagent bar keeps as skills.

**Key framing:** showcase = per-repo/single-app; ours = machine-global/cross-repo/vendor-neutral. Borrow *mechanisms* made repo-agnostic, never the app content. If the user surfaces another external claude setup to mine, apply the same filter: mechanisms yes, app-specific content and heavy runtime infra no.

**Spun off → automation epic #302 (OPEN, priority low)** — the reviewer vision grew into "automate PR review + issue planning (advisory LLM-in-CI)." User decided: dedicated epic, ACCEPT the LLM-in-CI infra/cost (an `ANTHROPIC_API_KEY` repo secret, scoped to `architecture`-labeled PRs), advisory-first (never a required check). Children: #303 spike (mechanism: GitHub Action vs headless `claude -p`; cost model; planner trigger event-vs-in-session — ADR), #304 CI advisory architecture review on `architecture` PRs, #305 planner subagent + a `plan-ready`/`plan-drafted`/`plan-reviewed` label protocol. Depends on the #300 persona (kept in #298). The pipeline: **backlog-manager grooms + sets `plan-ready`** → planner drafts plan → #300 reviewer critiques (`plan-reviewed`) → main agent implements → #304 reviews the PR. NOTE for future-me: those 3 pipeline labels are PROPOSED in #305, not created yet — don't treat them as live in gh_conventions until #305 ships.
