# Architecture Decision Records

Each ADR records one significant decision — what we chose, what we considered
and **rejected**, and why — as a durable, walkable file, so the design history
doesn't have to be excavated from closed issues and PRs.

## When to write one

Write an ADR when a decision is architecturally significant, cross-cutting,
long-lived, or expensive to reverse. A small, local, easily-reversed choice is a
PR description or a code comment, not an ADR — don't turn `docs/adr/` into a
dumping ground.

`adr-guard.yml` enforces only the _presence_ of a record: a PR labeled
`architecture` must add or modify a file here. The judgment of whether a change
_is_ architectural stays human — it's applied by adding the label.

## Creating one

ADRs are created with [adr-tools](https://github.com/npryce/adr-tools), which
numbers files sequentially and fills [`templates/template.md`](templates/template.md):

```sh
VISUAL=true adr new "Short decision title"       # next-numbered ADR from the template
VISUAL=true adr new -s 12 "Title"                # supersede ADR 12, linking both
```

- `VISUAL=true` is required — `adr new` otherwise opens `$EDITOR` and hangs when
  run non-interactively.
- `.adr-dir` (repo root) points `adr` at this directory, so the commands work
  from any subdirectory.

Then edit the generated file and fill in the sections. The **Alternatives
considered** section — each rejected option and _why_ — is the point: it's what
makes the design history walkable.

## Superseding

When a later decision replaces an earlier one, `adr new -s <old>` creates the new
ADR, marks the old one superseded, and links both — rather than editing the old
ADR to match the new reality. The rejected path staying visible is the point.
(adr-tools writes its own `Superceded by` spelling.)
