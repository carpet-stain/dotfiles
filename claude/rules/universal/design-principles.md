<!-- Universal design principles. Canonical source: my dotfiles. Loaded globally.
     How code and tools are shaped, not how work gets done (engineering-practices.md) or how
     the agent operates (ai-collaboration.md, communication.md). Layered-app architecture is
     domain-specific — see domain/architecture.md. Rationale: claude/README.md. -->

> ### GATE — applies always
>
> Applies everywhere; no placeholders, nothing to distill. Do NOT copy into repos.
> A repo's DESIGN.md/ADRs _illustrate_ these, never override them — read them and stay
> consistent. This is the source; the repo doc is the concrete expression.

# Design Principles

## Simplicity First

Write the minimum code that solves the problem. No speculative flags, no configurability nobody
asked for, no abstraction for a single call site, no handling for a case that can't happen.
Self-check: would a senior engineer call this overcomplicated?

## Configuration Is Code, Not Ambient State

Tooling config — linter rules, formatter settings, hooks, CI behavior — is a versioned file every
contributor and CI read, not someone's global dotfiles or IDE settings. One canonical config a
tool reads directly beats the same rule restated in several places that drift. Changing a rule is
a reviewable diff, not an invisible change to a local environment.

## Code Should Explain Itself To The Next Reader

Make obvious what owns a piece of logic, what boundary is crossed, what's already been validated,
and what failed when something breaks. Achieve it in order: good names, then clear structure, then
comments only where they preserve intent code can't. Comments explain _why_, not _what_ — don't
narrate mechanics a good name already conveys.

When the why is recoverable elsewhere (an ADR, an issue, a PR), the comment can be a pointer —
`# see ADR-0003` / `# see #142` — instead of restating that context inline. A pointer is not an
omission: it leverages provenance without dropping intent. The load-bearing, non-obvious tripwire
("removing this breaks X") still stays inline at the point of edit — a pointer supplements that,
never replaces it.

## Small, Composable Tools

One tool, one job, done well, composed through clean interfaces (stdin/stdout, exit codes, a small
flag surface). Prefer composing small tools over growing one behind a pile of flags. If a tool or
script does two unrelated jobs, split it — same one-sentence test as a code unit.

## Naming & Files

Names reveal meaning, ownership, and whether a value is raw, normalized, validated, or emitted —
not implementation trivia. Avoid vague names (`data`, `obj`, `tmp`) and dumping-ground files
(`utils`, `helpers`, `misc`). If a unit can't be described in one sentence, it's doing too much.

## Logs Are For Diagnosis, Output Is For Humans

Logs make failures diagnosable after the fact; user-facing output guides the operator now — don't
substitute one for the other. Use log levels intentionally; keep logging close to the code that
owns the truth. User-facing output reads as a concise narrative: one structured block over
scattered lines, caveats before success, never make the reader read logs for an ordinary mistake.
