<!-- LAYER 0 — universal engineering philosophy. Canonical source: my dotfiles.
     Loaded globally for every project. Language- and platform-agnostic. -->

> ### APPLIES ALWAYS — no composition needed
> These principles apply in their abstract form everywhere; there are no placeholders
> to fill and nothing to distill into a repo. Do NOT copy this layer into repos.
> If a repo documents its own design rationale (e.g. docs/DESIGN.md, ADRs), read it to
> see how these principles are realized in that codebase, and stay consistent with its
> recorded decisions. That repo doc is the concrete expression; this layer is the source.
> This layer is never "overridden" by a repo — a repo doc illustrates it, it does not
> replace it.

# Engineering Philosophy

These are directives for how I want code designed, changed, tested, and shipped — everywhere.
When a repository's own documents are more specific, follow those; they realize these principles.

## Be Explicit — Write It Down Over Committing To Memory

Strongly prefer explicitness. Write things down in the project rather than keeping them as tribal
knowledge, chat memory, or an assumption in someone's head.

- Prefer explicit contracts, typed errors, named options, and documented behavior over implicit
  convention or "you just have to know."
- When you learn or decide something a future reader would need again — a command sequence, an
  environment fact, a gotcha, the meaning of an output — record it in the appropriate durable place
  rather than relying on memory or a single conversation.
- Prefer durable artifacts (docs, tests, templates, comments that preserve reasoning) over
  session-only knowledge.
- If behavior is surprising, make it explicit at the source: a clearer name, a typed error, a doc
  note, or a regression test — not a mental note.
- Do not answer a recurring question the same way twice from memory; put the answer where it will be
  found next time.

## Verify, Don't Trust

When analyzing or summarizing something drawn from a resource (web page, tool call, provided
document), do not trust a memory or retained summary of it. Retrieve the resource afresh and compare
it to the summary you are preparing, adversarially: fact-check your own work assuming it contains
errors and hallucinations until proven otherwise.

## Work Through Human Toolchains

Operate through the same interfaces, commands, and guardrails a human contributor on this project
would use — the build targets, test runners, linters, formatters, hooks, and review flow the project
already provides. This is a safeguard, not a convenience: an agent's work should be as inspectable,
reproducible, and revertible as a human's, and confining it to human-facing toolchains is what keeps
it so.

- Prefer the project's provided entry points (a `make`/task target, a script, a documented command)
  over hand-rolled substitutes or direct calls that skip what those wrappers set up.
- Do not invent a private path around a safeguard: no bypassing CI or pre-commit gates, no
  out-of-band edits that skip the checks a human's change would face, no privileged side channel a
  human wouldn't have.
- Keep actions reversible and reviewable. Favor changes a human can inspect as a normal diff and
  undo with normal tools; avoid irreversible or hard-to-audit operations.
- If a safeguard is wrong or in the way, surface it and propose changing it — do not route around it
  silently.
- Do not self-authorize beyond what a human in the same seat would do; when an action is
  irreversible or exceeds that scope, stop and involve a human.

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

## Testing By Layer

Different layers prove different things: core tests prove invariants; boundary tests prove
normalization and error translation; orchestration tests prove sequencing and stage behavior; output
tests prove artifact and logging contracts. Prefer focused tests near the boundary where behavior
lives, fakes over live infrastructure, and regression tests placed where the bug lived. Don't turn
every question into an end-to-end test, and don't leave a test in a package that no longer owns the
behavior.

## Refactoring

Refactor to improve boundary clarity, separation of concerns, naming accuracy, testability, and
explicit handoffs, or to remove accidental duplication. Good refactors move logic toward the layer
that should own it. Avoid abstraction without a real boundary, hiding sequencing, centralizing
unrelated concerns into generic utility packages, or splitting files in ways that obscure ownership.

## Documentation Is Part Of The Change

Update docs when behavior or architecture changes — user-visible behavior, design/seam changes,
standards, and durable decisions each have a home. Before a structural change, read the recorded
decisions and stay consistent with them; if one must change, supersede it explicitly rather than
letting code and recorded intent drift apart. Write down anything the next reader will need.

## Version Control Discipline

- **Review before committing.** Don't commit or push on your own initiative; show what changed and
  get explicit approval, then commit only what was approved.
- **Commit freely while developing** on the working branch; intermediate checkpoints are expected.
- **Main-line history is clean.** Each merged change is one clear, complete, squashed commit
  describing the whole change — not its iteration history.
- **Rebase onto latest main-line before merging.**
- **Never rewrite history you don't own.** The only sanctioned force-push is the deliberate rewrite
  of your own just-squashed branch, and it must abort if the remote moved unexpectedly.
- If the remote moved unexpectedly, stop and inspect before doing anything destructive; realign
  rather than overwrite.

## Before Finishing, Ask

- Does the change live in the layer that should own it?
- Is the naming semantic rather than shape-based?
- Did any backend-specific behavior leak past its boundary?
- Are logs diagnostic and user-facing output concise?
- Do tests prove the right boundary or invariant?
- Do the docs reflect the new behavior, and did I write down what the next reader will need?

## Final Rule

If unsure: convert external reality into stable internal meaning as early as possible, keep each
layer responsible for one kind of problem, be explicit and write things down, and leave the next
reader with obvious ownership and meaning.
