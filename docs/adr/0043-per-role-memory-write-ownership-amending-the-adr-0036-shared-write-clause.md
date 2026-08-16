# 43. Per-role memory write-ownership, amending the ADR-0036 shared-write clause

Date: 2026-08-14

## Status

Accepted

Amends ADR-0036's any-agent-writes clause only; ADR-0036 stays Accepted — the MCP
knowledge-graph server and its private local store are untouched.

Superceded 2026-08-16 by
[46. Hosted per-role agent memory over MCP-over-HTTP](0046-hosted-per-role-agent-memory-over-mcp-http.md)
— the "one store per role" rejection reverses; the shared-reference tier and the
anti-smuggling rule dissolve with it.

## Context

ADR-0036 put agent memory in one MCP knowledge graph backed by a private local JSONL store.
Any agent that loads the server can write any entity; nothing scopes a write to the role that
made the decision. That was right for one agent — the backlog-manager was the guinea pig — and
it stops being right the moment the roster in ADR-0042 has several roles with deliberately
separate lanes.

The problem it creates: ADR-0042's whole lane-keeping argument is that an agent must be unable
to _act_ or _keep_ across lanes. A shared, unscoped graph is the keeping half. The architect
can write grooming rationale, the backlog-manager can write design rationale, and the memory
that was supposed to be each role's moat becomes a cross-lane back-channel — the one place the
handoff boundary silently doesn't hold.

Enforcement needs agent identity in the write path (ADR-0035, #540, **UNBUILT**) plus a
write-scoping layer over the MCP store (#542). Neither exists, so this records the contract and
what has to be built for it, not a live control.

## Decision

Memory splits into two tiers, and the split is the contract:

- **Shared reference** — facts recoverable from the repo itself: config locations, what a CI
  check enforces, the ADR index. Decisionless. Any role writes, every role reads. It is a
  cache, not a decision.
- **Owned decision** — why we chose X: grooming, design, and priority rationale. It carries
  authority, so it is scoped to the deciding role and never written by another.

**Anti-smuggling rule:** the reference tier may hold only repo-recoverable facts. The moment a
fact encodes a decision or its rationale it is owned, whatever tier it was written to. Without
that rule the reference tier becomes exactly the back-channel the tiers exist to prevent.

The reference-versus-decision content split is the one ADR-0036 already carries forward from
ADR-0033, and it holds today as instruction.

**To build:** per-role write-ownership enforced in the write path, gated on identity (#540) and
a write-scoping layer on the MCP store (#542). Until then the owned tier is discipline, not a
property to lean on, and the read-only `audit-memory` skill (#315) is the detection backstop —
it catches cross-lane writes after the fact instead of refusing them.

## Alternatives considered

- **Leave the graph unscoped** (ADR-0036 as written) — simplest, and fine while one agent
  writes. Rejected once the roster has separate lanes: shared memory is precisely how a lane
  boundary leaks without anyone acting across it.
- **Supersede ADR-0036** — wrong relation, the same call ADR-0037 and ADR-0038 made against
  ADR-0035. The server, the private store, and the recall model are all live; only the
  any-agent-writes clause changes.
- **One store per role** — enforces ownership by construction with no identity work, but kills
  the shared-reference tier and the cross-role reads that make a team graph worth more than
  private notes. Rejected: it solves scoping by removing sharing.
- **A custom MCP server enforcing the contract in code** — ADR-0036 already weighed and
  deferred this; it stays the shape write-scoping most likely takes, decided in #542 rather
  than here.
- **Instruction only, no enforcement ever** — what exists today. Kept as the interim, rejected
  as the end state: ADR-0042's own argument is that prose cannot hold a boundary an agent has
  a reason to cross.

## Consequences

The moat stays per-role instead of pooling into a shared blur, and the tier a fact belongs to
is answerable by one question — is it recoverable from the repo? Until identity and
write-scoping ship, that answer is enforced by instruction with `audit-memory` as the backstop,
so a cross-lane write is detected rather than prevented.

Write-scoping now has a stated contract to build against in #542, and it inherits ADR-0035's
identity dependency: no author in the write path, no ownership to enforce.

Revisit if the audit keeps finding decision content in the reference tier (the contract needs
teeth sooner, or the line is drawn wrong), or if the roster stays at two agents long enough
that per-role scoping is cost without a lane to protect.
