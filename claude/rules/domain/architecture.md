<!-- Application-architecture principles. Canonical source: my dotfiles. Domain-level, NOT
     universal: applies only when building software with distinct internal layers (a service, a
     CLI with orchestration, a library with a public contract). Extracted from design-principles.md
     so it stops loading in config/script/dotfiles repos. Rationale: claude/README.md. -->

> ### GATE
>
> Applies only when this repo builds an application with distinct internal layers — a service, a
> CLI with real orchestration, a library with a public contract. SKIP for pure config, dotfiles,
> scripts, or single-purpose tools: wrong context there, not merely unnecessary.
> Like the universal principles, a repo's DESIGN.md/ADRs _illustrate_ these, never override them.

# Application Architecture

The layer-boundary discipline a layered application needs and a config repo or script does not.
The universal Design Principles still apply on top of these.

- **Thin front end.** The entry surface parses input, validates usage, resolves config, composes
  dependencies, renders output — it doesn't own core rules, orchestration, or backend quirks. If
  logic would still matter behind a different front end, it belongs deeper.
- **Use-cases own sequencing.** Orchestration owns stage ordering, typed request/result/error
  contracts, and when to fail and what to emit — not transport parsing or a grab-bag of rules.
- **Domain before transport.** Normalize external inputs into stable internal models before they
  reach core logic; never pass raw transport shapes deep in or reuse them as canonical models.
- **Invariants near the model**, not scattered through ad-hoc branching.
- **Compose at the edge.** Explicit dependency injection: small interfaces, runtime selection at
  the top; lower layers receive dependencies, never discover globals or process state.
- **Backend quirks stay at the boundary** — solved near their adapter, not spread across core logic.
- **Artifacts are contracts.** Anything a run emits is part of the contract; keep generation near
  the serialization boundary, don't let file-format concerns reshape the core model.

Governing idea: convert external reality into stable internal meaning as early as possible, and
keep each layer responsible for exactly one kind of problem.
