<!-- LAYER 0 — universal engineering practices. Canonical source: my dotfiles.
     Loaded globally for every project. Language- and platform-agnostic.
     How work gets done over time (testing, docs, refactoring, security), not how
     code is shaped in the moment (see design-principles.md). -->

> ### APPLIES ALWAYS — no composition needed
> These principles apply in their abstract form everywhere; there are no placeholders
> to fill and nothing to distill into a repo. Do NOT copy this layer into repos.
> If a repo documents its own testing/security conventions, read them and stay
> consistent — that repo doc is the concrete expression; this layer is the source.

# Engineering Practices

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

## Security By Default

Flag common vulnerability classes (injection, unsafe deserialization, path traversal, secrets in
code, and similar) even when not asked — don't wait to be prompted about a risk that's visible in
the diff. Secrets live in an environment file or a secret manager, gitignored, never hardcoded or
committed, even temporarily.

## Documentation Is Part Of The Change

Update docs when behavior or architecture changes — user-visible behavior, design/seam changes,
standards, and durable decisions each have a home. Before a structural change, read the recorded
decisions and stay consistent with them; if one must change, supersede it explicitly rather than
letting code and recorded intent drift apart. Write down anything the next reader will need.

For a repo with real multi-session or multi-contributor handoff needs, a committed, human-readable
status/next-task file (current progress, what's next, anything a fresh session would need) is worth
keeping current — not a mandate for every repo, but a judgment call where picking up mid-task
actually happens often.

## Before Finishing, Ask

- Did I flag any visible security risk (secrets, injection, unsafe input) unprompted?
- Do tests prove the right boundary or invariant?
- Do the docs reflect the new behavior, and did I write down what the next reader will need?
