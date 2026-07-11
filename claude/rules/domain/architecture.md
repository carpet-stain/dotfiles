<!-- Application-architecture principles. Canonical source: my dotfiles.
     Domain-level, NOT universal: applies only when building software with distinct
     internal layers (a service, a CLI with orchestration, a library with a public
     contract). For pure config, dotfiles, scripts, or single-purpose tools these do
     not apply — see the GATE. Language- and platform-agnostic within that scope.
     Extracted from design-principles.md so it stops loading in non-application repos. -->

> ### GATE
> Applies only when this repo builds an application with distinct internal layers — a service,
> a CLI with real orchestration, a library with a public contract. SKIP for pure config,
> dotfiles, shell scripts, or single-purpose tools: there's no layering for these rules to
> govern, so they're wrong context there, not merely unnecessary.
> Like the universal principles, a repo never *overrides* these — a repo's DESIGN.md or ADRs
> *illustrate* how they're realized in that codebase. Read those and stay consistent; this is
> the source, the repo doc is the concrete expression. No placeholders, nothing to compose.

# Application Architecture

How code is shaped once a codebase has real internal layers. The universal Design Principles
(simplicity, self-explaining code, semantic naming, small composable tools) still apply on top of
these — this file adds only the layer-boundary discipline that a layered application needs and a
config repo or script does not.

## Layered Design

- **Keep the front end thin.** The entry surface parses input, validates usage, resolves config,
  composes dependencies, and renders output. It should not own core rules, orchestration, backend
  quirks, or artifact generation. If logic would still matter behind a different front end, it
  belongs deeper.
- **Use-cases own sequencing.** Orchestration layers own stage ordering, typed request/result/error
  contracts, dependency seams, and the decisions of when to fail and what to emit — not transport
  parsing or a grab-bag of rules.
- **Domain before transport.** External systems do not define internal meaning. Normalize external
  inputs into stable internal models before they reach core logic. Never pass raw transport shapes
  deep into core logic or reuse them as canonical models.
- **Keep invariants near the model.** Stable correctness rules belong near the models or validation
  boundary they protect, not scattered through ad-hoc branching.
- **Compose at the edge.** Use explicit dependency injection: small interfaces or function seams,
  runtime selection at the top, lower layers receive dependencies and never discover globals or
  process state.
- **Backend quirks stay at the boundary.** Solve an awkward external system as close to its adapter
  as possible; do not spread its special cases across core logic, presentation, or the front end.

Governing idea: **convert external reality into stable internal meaning as early as possible, and
keep each layer responsible for exactly one kind of problem.**

## Artifacts Are Contracts

Anything a run emits for a human or downstream tool is part of the contract. Keep artifact generation
near the serialization boundary; do not let file-format concerns reshape the core model. Declare each
artifact's meaning explicitly; keep the decision of *when* to emit with the owning use-case and the
*how* with the output layer.

## Final Rule

If unsure: convert external reality into stable internal meaning as early as possible, and keep
each layer responsible for one kind of problem.
