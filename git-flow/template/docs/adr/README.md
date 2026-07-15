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

Create ADRs with the shipped tool — never hand-number or hand-format them.
`scripts/new-adr.sh` stamps the next sequential number and fills
[`templates/template.md`](templates/template.md); the `just adr` recipe wraps it:

```sh
just adr "Short decision title"       # next-numbered ADR from the template
```

It's a plain, runner-agnostic script rather than adr-tools (which has no Debian
package), so it works on any machine the repo runs on. Then edit the generated
file and fill in the sections. The **Alternatives considered** section — each
rejected option and _why_ — is the point: it's what makes the design history
walkable.

## Superseding

When a later decision replaces an earlier one, create the new ADR, then set the
old one's Status to `Superseded by NNNN` (and the new one's to `Supersedes NNNN`)
rather than editing the old ADR to match the new reality. The rejected path
staying visible is the point.
