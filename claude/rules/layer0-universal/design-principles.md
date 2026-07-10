<!-- LAYER 0 — universal design principles. Canonical source: my dotfiles.
     Loaded globally for every project. Language- and platform-agnostic.
     How code and tools are shaped, not how work gets done (see engineering-practices.md)
     or how the agent operates (see ai-collaboration.md, communication.md). -->

> ### APPLIES ALWAYS — no composition needed
> These principles apply in their abstract form everywhere; there are no placeholders
> to fill and nothing to distill into a repo. Do NOT copy this layer into repos.
> If a repo documents its own design rationale (e.g. docs/DESIGN.md, ADRs), read it to
> see how these principles are realized in that codebase, and stay consistent with its
> recorded decisions. That repo doc is the concrete expression; this layer is the source.
> This layer is never "overridden" by a repo — a repo doc illustrates it, it does not
> replace it.

# Design Principles

How I want code, tools, and configuration shaped — everywhere. When a repository's own
documents are more specific, follow those; they realize these principles.

## Simplicity First

Write the minimum code that solves the problem. No speculative flags, no configurability nobody
asked for, no abstraction for a single call site, no error handling for a scenario that can't
happen. Self-check: would a senior engineer call this overcomplicated? If yes, cut it back.

## Configuration Is Code, Not Ambient State

Tooling configuration — linter rules, formatter settings, hook definitions, CI behavior — is a
versioned file in the repo, not a contributor's global dotfiles, IDE settings, or personal
defaults. Same idea as Infrastructure as Code, applied to the toolchain itself.

- If a rule matters, it lives in a config file every contributor and CI both read — not a wiki
  page, a chat message, or "everyone just remembers to pass these flags."
- One canonical config a tool reads directly beats the same rule restated in several places (an
  IDE setting *and* a CI flag *and* a doc) that can silently drift apart.
- Changing a rule is a reviewable diff to that file, not an undocumented change to someone's local
  environment that the next contributor can't see or reproduce.

## Code Should Explain Itself To The Next Reader

Working code is not enough. Code should make obvious to the next reader what owns a piece of logic,
what boundary is being crossed, what data has already been normalized or validated, what invariant is
being enforced, and what stage failed when something goes wrong. Legibility is a first-class goal, not
a nicety.

Achieve it in order of preference: good names first, clear structure second, comments only where they
preserve intent that code alone cannot. Comments are for reasoning, not narration — explain *why* a
boundary, normalization, or unusual choice exists; do not restate obvious mechanics a good name
already conveys. Before writing a comment, ask whether a better name or clearer structure would remove
the need for it.

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

## Small, Composable Tools

The Unix philosophy — one tool, one job, done well, composed through clean interfaces — is
Layered Design's counterpart outside the codebase. It governs which tools get reached for and how
scripts or CLIs get shaped, not just how a codebase's internals are structured.

- Prefer a small tool that does one thing over a monolithic one that does many unrelated things
  behind a pile of flags. Compose several small tools rather than growing one to cover every case.
- Give a script or CLI a narrow, well-defined job with a clean interface — stdin/stdout, exit
  codes, a small flag surface — so it composes with pipes and other tools instead of needing a
  bespoke integration.
- If a tool or script is doing two unrelated jobs, split it. Same test as a code unit: can it be
  described in one sentence?

## Naming & Files

Names should reveal semantic meaning, ownership, level of abstraction, and whether a value is raw,
normalized, validated, or emitted. Prefer names that describe responsibility or transformation, not
implementation trivia; avoid vague names (`data`, `obj`, `tmp`, `thing`). Prefer typed errors whose
names preserve stage meaning. Keep files topical and narrow; avoid dumping-ground files
(`utils`, `helpers`, `misc`, `common`). If a unit can't be described in one sentence, it's doing too
much.

## Logs Are For Diagnosis, Output Is For Humans

Keep a strong distinction: logs make failures diagnosable after the fact; user-facing output guides
the operator now. Do not use one as a substitute for the other. Use log levels intentionally
(detailed diagnostics; normal progress; degraded/partial; stopping failures). Keep logging close to
the layer that owns the truth. User-facing output should read as a concise narrative: prefer one
structured block over overlapping lines, surface caveats before success, use action-oriented
language, and never force the reader to read logs for ordinary mistakes.

## Artifacts Are Contracts

Anything a run emits for a human or downstream tool is part of the contract. Keep artifact generation
near the serialization boundary; do not let file-format concerns reshape the core model. Declare each
artifact's meaning explicitly; keep the decision of *when* to emit with the owning use-case and the
*how* with the output layer.

## Before Finishing, Ask

- Does the change live in the layer that should own it?
- Is a tool or script doing one job well, or several unrelated ones that should split?
- Could this be simpler — any speculative code, flags, or handling for the impossible?
- Is tooling configuration committed as versioned code, not left to ambient/personal defaults?
- Is the naming semantic rather than shape-based?
- Did any backend-specific behavior leak past its boundary?
- Are logs diagnostic and user-facing output concise?

## Final Rule

If unsure: convert external reality into stable internal meaning as early as possible, and keep
each layer responsible for one kind of problem.
