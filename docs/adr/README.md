# Architecture Decision Records

Each ADR records one significant decision — what we chose, what we considered
and **rejected**, and why — as a durable, walkable file, so the design history
doesn't have to be excavated from closed issues and PRs. See
[`AGENTS.md`](../../AGENTS.md) for _when_ a decision rises to an ADR.

## Creating one

ADRs are created with [adr-tools](https://github.com/npryce/adr-tools)
(installed via `macos/Brewfile.dev`), which numbers files sequentially and fills
[`templates/template.md`](templates/template.md). The `just adr` recipe wraps
it:

```sh
just adr "Short decision title"          # next-numbered ADR from the template
ADR_DATE=2026-07-11 just adr "Title"     # stamp a specific date (backfilling)
just adr -s 12 "Title"                   # supersede ADR 12, linking both
```

- The recipe sets `VISUAL=true` so `adr new` writes the file without opening
  `$EDITOR` (which otherwise hangs non-interactively) — then edit the generated
  file to fill in the sections.
- `.adr-dir` (repo root) points `adr` at this directory, so the commands work
  from any subdirectory.
- adr-tools is macOS-only here — no Debian apt package. Install it by hand on
  Linux if it's ever needed there.

Then edit the generated file and fill in the four sections. The
**Alternatives considered** section — each rejected option and _why_ — is the
point: it's what makes the design history walkable.

## Superseding

When a later decision replaces an earlier one, `adr new -s <old>` creates the
new ADR, marks the old one superseded, and links both — rather than editing the
old ADR to match the new reality. The rejected path staying visible is the
point. (adr-tools writes its own `Superceded by` spelling.)

## Template

[`templates/template.md`](templates/template.md) is the adr-tools template:
Status, Context, Decision, Alternatives considered, Consequences.
