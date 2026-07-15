# 1. Record architecture decisions

Date: DATE

## Status

Accepted

## Context

We need to record the architecturally significant decisions made on this
project — what was chosen, what was rejected, and why — so the design history is
walkable later instead of excavated from closed issues and PRs. Without a durable
home, the _why_ behind a decision gets re-litigated every time someone questions
it.

## Decision

Use Architecture Decision Records, as [described by Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).
ADRs live in `docs/adr/`, are numbered sequentially, and follow
[`templates/template.md`](templates/template.md): Status, Context, Decision,
Alternatives considered, Consequences. Manage them with
[adr-tools](https://github.com/npryce/adr-tools) — see
[`README.md`](README.md) for the workflow.

## Alternatives considered

- **No formal record** — leave decisions in issues, PRs, and commit messages.
  Rejected: the _why_ scatters across closed threads and can't be walked; it's
  the exact excavation problem ADRs exist to solve.
- **A single running design doc** — one file everyone edits. Rejected: it loses
  the per-decision status and superseding history, and rejected alternatives get
  overwritten rather than staying visible.

## Consequences

Every significant decision leaves a distilled, durable record. `adr-guard.yml`
enforces that a PR labeled `architecture` ships one. Superseding a decision links
the old and new ADRs rather than editing history, so the rejected path stays
visible.
