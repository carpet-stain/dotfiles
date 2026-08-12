---
name: project-deal-finder
description: Deal-finder — personal marketplace monitor; repo now exists (created 2026-07-26), its backlog not yet built — re-supply spec then build the epic
metadata:
  type: project
---

New personal project (secondhand PC-parts marketplace monitor: poll sources, filter against an
in-progress build's needs, LLM-judge fit, notify — notify-only, no auto-purchase, no adversarial
scraping). **The user owns the spec and explicitly leaves language/framework/host to the
implementing session — not mine to design.** The full spec text lives in the originating
conversation, not restated here: when the repo exists, ask the user to re-supply it rather than
re-deriving it from memory.

**Repo now exists:** `carpet-stain/deal-finder` created 2026-07-26 (via infra#75, `repos.tf`).
Scaffolding follows project-starter-template's bootstrap runbook; watch the GH013
protection-before-first-commit gotcha ([[project-gitflow-starter]]).

**Pending — build its backlog (unblocked, not yet done):** an epic mapping the spec's goals to a
suggested build sequence (first vertical slice: one source → normalizer → filter → LLM analysis →
notification → seen-set). Ask the user to re-supply the spec first (above). Per ADR-0033 residency,
that backlog and its facts live in **deal-finder's own store** once built — this dotfiles entry then
slims to a `map_deal-finder` pointer; nothing is filed here.
