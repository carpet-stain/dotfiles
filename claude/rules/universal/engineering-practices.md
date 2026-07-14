<!-- Universal engineering practices. Canonical source: my dotfiles. Loaded globally.
     How work gets done over time (testing, docs, refactoring, security), not how code is
     shaped in the moment (design-principles.md). Rationale: claude/README.md. -->

> ### GATE — applies always
>
> Applies everywhere; no placeholders, nothing to distill. Do NOT copy into repos.
> A repo's own testing/security docs are the concrete expression; this is the source.

# Engineering Practices

## Testing By Layer

Different layers prove different things — invariants at the core, normalization and error
translation at the boundary, sequencing in orchestration. Prefer focused tests near the behavior,
fakes over live infrastructure, and regression tests where the bug lived. Don't make everything
end-to-end, and don't leave a test in a package that no longer owns the behavior.

## Refactoring

Refactor for boundary clarity, separation of concerns, naming, testability, or to remove
accidental duplication — moving logic toward the layer that should own it. Avoid abstraction
without a real boundary, hidden sequencing, or splits that obscure ownership.

## Security By Default

Flag common vulnerability classes (injection, unsafe deserialization, path traversal, secrets in
code) even when not asked — don't wait to be prompted about a risk visible in the diff. Secrets
live in an environment file or secret manager, gitignored, never hardcoded or committed.

## Documentation Is Part Of The Change

Update docs when behavior or architecture changes. Before a structural change, read the recorded
decisions and stay consistent; if one must change, supersede it explicitly rather than letting
code and intent drift. For a repo with real multi-session or multi-contributor handoff, keep a
committed status/next-task file current — a judgment call, not a mandate.

A major, cross-cutting, or expensive-to-reverse decision is "recorded" in an ADR — the
decision plus what was considered and rejected, not just the outcome — so it stays
walkable later instead of requiring an excavation of closed issues/PRs. A repo's own
docs define where that ADR lives and its exact template; this principle only says the
artifact belongs somewhere durable, not buried in ephemeral history.
