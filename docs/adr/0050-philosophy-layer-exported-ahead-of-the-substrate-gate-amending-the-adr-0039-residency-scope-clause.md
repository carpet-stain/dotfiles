# 50. Philosophy layer exported ahead of the substrate gate, amending the ADR-0039 residency scope clause

Date: 2026-08-20

## Status

Accepted

Amends ADR-0039's residency-scope note only; ADR-0039 stays Accepted.

## Context

ADR-0039 decided definition residency: agent definitions move to `carpet-stain/agents` now.
\#545's Export seam deliberately decoupled that from a second thing — the operating-model
_machinery_ export (roster, ceremonies, telemetry) — which stays gated on the event-driven
substrate (#576) being real, with dotfiles as the proving ground until then.

On 2026-08-19 the decided **philosophy layer** — the core invariant, the 10 principles, and the
decision index — was exported early to `carpet-stain/agents` as `docs/operating-model.md`
(agents#22), ahead of that substrate gate. This was a reasonable call: the doc carries no
machinery, only already-Accepted decisions cited by pointer back to their dotfiles ADRs/issues —
the substrate gate exists to keep unbuilt machinery from leaking out prematurely, not to hold
back a stable framework doc. But left unrecorded, ADR-0039's residency scope silently drifts:
two different things now live in `carpet-stain/agents` on two different timelines, and ADR-0039
only describes one of them.

## Decision

Record the split already made; this does not reopen it.

- The **philosophy layer** (`docs/operating-model.md`, agents#22) lives in `carpet-stain/agents`
  now. Each section cites the dotfiles ADR/issue that decided it — the doc is a cohesive map,
  never a second copy of the decision.
- The **operating-model machinery export** (roster, ceremonies, telemetry) stays gated on #576,
  unchanged from ADR-0039/#545's original decoupling.
- dotfiles ADRs stay the atomic decision homes either way — residency of the _doc_ doesn't move
  where a decision is _made_.

## Alternatives considered

- **Hold the philosophy doc back until the substrate gate clears** — rejected: it's already
  Accepted and stable, and carries no machinery; withholding it to keep one clean gate date trades
  away a useful doc for tidiness.
- **Record this as a comment on #545 instead of an ADR** — rejected: ADR-0039 itself makes the
  residency claim that's now stale. A comment elsewhere doesn't correct the record that's wrong.
- **Supersede ADR-0039 outright** — wrong relation: the submodule/pull-latest residency decision
  is unchanged and still live; only its scope note needs correcting, which a clause amendment
  does without marking the whole decision dead.

## Consequences

ADR-0039's Status now carries a dated pointer to this ADR, so a reader lands on the accurate
scope without ADR-0039's body needing edits. `carpet-stain/agents#22` and #545 both cross-reference
this ADR, so the split is walkable from either side. Revisit only when #576 lands and the
roster/ceremonies/telemetry export needs recording — that's a new decision, not a further
amendment to this one.

Deciding record: #658. Companion doc: `carpet-stain/agents#22`. Original split: #545's Export
seam / ADR-0039.
