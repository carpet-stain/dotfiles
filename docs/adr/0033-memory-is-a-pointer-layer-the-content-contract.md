# 33. Memory is a pointer layer — the content contract

Date: 2026-07-25

## Status

Accepted

References [ADR-0009](0009-backlog-manager-subagent-with-committed-file-based-memory.md)
(which it does not amend or supersede — nothing in 0009 is reversed).

## Context

Backlog-manager's committed memory (`.claude/agent-memory/backlog-manager/`)
had no enforced content contract and drifted into narrative files restating
what other artifacts own. Every consequence was observed, not hypothetical:
staleness by construction — embedded status decays the moment an issue moves
(#314); heavy review diffs on every memory-sync PR, the burden that fuels
auto-merge pressure (#411); sprawl. The one-home-per-fact rule already
assigns owners — issues own live status, ADRs own decisions, AGENTS.md owns
how-to-work — but nothing bound memory to it (#416).

One axis disambiguation, so this isn't misread as reversing ADR-0009: what
0009 rejected was a _commit-granularity_ split (doc-like files committed,
notes kept local). This contract is _content-placement_ — what belongs in
memory at all. Everything in memory stays committed whole, exactly per 0009.

## Decision

Memory is a **pointer layer, not a narrative**. The contract binds to the
four existing frontmatter types — no new taxonomy:

- **`project`** — the decision, its why, a pointer to where the live record
  is (issue, ADR, PR), and any non-recoverable lesson. **Never restated
  issue status**: no embedded OPEN/CLOSED, no copied acceptance criteria, no
  "current state" prose — the issue owns those.
- **`reference`** — pointers plus backlog/labeling operating conventions,
  as categorical definitions ("a theme label earns creation at ~3+ issues"),
  never per-file inventories or session narratives.
- **`user` / `feedback`** — unchanged; they're about how to work with the
  maintainer, which no repo artifact owns.

The platform injects a memory-type description this ADR cannot read or
override; where the agent's applied contract and that injected description
differ for backlog-manager's committed memory, the agent follows this
contract. That is instruction, not platform enforcement — the same
convention boundary as ADR-0027 — and whether this contract narrows or
merely refines the injected spec is unverifiable in-repo; named here as an
assumption, not a claim.

Enforcement is the `audit-memory` skill's existing Misplaced-durable-content
check, generalized (no sixth check): its promotion targets become the
durable documentation homes — README, AGENTS.md, or an ADR — with this ADR
as its spec. Two boundaries stay fixed: the skill's `adr/` read-exclusion
stands (an ADR is a _proposal target_ for promotion, never a read-surface
for de-dup suppression — promotion leaves only a pointer behind, so there is
nothing left to false-positive on), and "the issue" is not a promotion
target for that check — memory↔issue traffic is already owned by the
Staleness and One-home checks; the fifth check stays the doc↔memory sibling.

The contract binds backlog-manager wherever it runs, judged against each
repo's own doc homes — carpet-stain/infra's memory store gets its own slim
there as a follow-up, not here.

## Alternatives considered

- **A new content taxonomy** (a parallel five-category vocabulary for what
  memory may hold) — rejected: it would be a third overlapping type system
  next to the frontmatter types and the doc-home split, and the four
  existing types already partition the content cleanly once each gets a
  contract.
- **Amending or superseding ADR-0009** — rejected: nothing in 0009 is
  reversed; the commit-whole decision and the human-review checkpoint stand.
  A reference plus a one-line back-footer keeps the chain walkable without
  implying reversal.
- **A sixth audit-memory check for contract violations** — rejected: the
  existing fifth check already owns the doc↔memory boundary; generalizing
  its promotion targets covers the contract without a new check to keep
  consistent with the other five.

## Consequences

Memory files become index-plus-pointer entries; sync-PR diffs shrink to
what actually changed in the agent's own knowledge, making the human review
checkpoint cheap (the precondition #411 wants before any auto-merge
discussion). Staleness-by-construction disappears where the contract is
followed, and `audit-memory` detects where it isn't.

The cost is a discipline: some context a future session might want inline
now sits one pointer away (a `gh issue view` or ADR read). That trade is
deliberate — the pointer is always current; the restatement never was.

Revisit if: the frontmatter type system itself changes upstream, or the
pointer form proves too lossy in practice (sessions repeatedly re-deriving
what a slimmed entry used to hold inline — that would argue the lesson
belonged in memory after all, and the contract's `project` lesson clause
should widen).
