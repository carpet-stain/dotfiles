---
name: project-deal-finder
description: Deal-finder — personal marketplace monitor; repo creation routes through infra#75, real backlog gets built once the repo exists
metadata:
  type: project
---

New personal project (secondhand PC-parts marketplace monitor: poll sources, filter against an
in-progress build's needs, LLM-judge fit, notify — notify-only, no auto-purchase, no adversarial
scraping). **The user owns the spec and explicitly leaves language/framework/host to the
implementing session — not mine to design.** The full spec text lives in the originating
conversation, not restated here: when the repo exists, ask the user to re-supply it rather than
re-deriving it from memory.

**Why no repo yet:** creation routes through infra's `repos.tf` (see [[reference-infra-repo]]) —
filed as infra#75. Scaffolding then follows project-starter-template's bootstrap runbook; watch
the GH013 protection-before-first-commit gotcha ([[project-gitflow-starter]]).

**My part, once the repo exists:** build the real backlog there — an epic mapping the spec's
goals to its own suggested build sequence (first vertical slice: one source → normalizer →
filter → LLM analysis → notification → seen-set). Nothing is filed or labeled until then.
