---
name: project-agent-operating-model
description: The "agents as managed team members" north-star (epic #545) + the shipped-work authorship decision (ADR-0037/#544) — decisions, whys, non-recoverable lessons
metadata:
  type: project
---

**North-star — "agents as managed team members" (epic #545, incubation).** The operating model for
treating AI agents as shared, *managed* team members, not personal tools, cohesive with existing SWE
ceremonies. Home = #545 — read it for the 8 principles (own identity · shared-memory-as-moat ·
structural-edge roster filter · least-resistance-over-enforcement · team-wide-default with the
implementor as the individually-invoked exception · invoked-in-natural-processes /
invitation-is-authorization · manageable+measured · provider-agnostic). Don't restate; point.
Core invariant: **the human gates the decision, not the labor.** Still forming; exports to its own
(provider-agnostic) repo once the event-driven substrate is real. Builds on ADR-0035 (#540
identities/voices) + ADR-0036 (#542 MCP memory). Two tracks are UNBUILT and need shaping before
they're issues: event-driven invocation substrate, observability/telemetry.

**Authorship (ADR-0037, #544) — agent authors, maintainer ships.** Git author = the
`implementor` identity (honest blame, author-anchored, preserved under rebase-merge). Committer =
merger = maintainer (rebase-merge rewrites it) — accepted as the honest "who shipped it" +
accountability anchor. **Graph-level machine-vs-human separation is an explicit NON-GOAL**; the real
metric is built off the author field + provenance trailers in #545's observability track, not
GitHub's contribution graph (the wrong instrument). Why reopening one-day-old ADR-0035 was
justified, not churn: the team/audit frame it never weighed, *and* the git-native author/committer
split **separates authorship (who typed → blame) from ownership (who's accountable → merger)** —
dissolving 0035's "he owns it" objection rather than negating it.

**Non-recoverable lessons:**

- **Git author is independent of the push token** → honest agent attribution needs only a
  machine-user email (noreply `{id}+name@users.noreply.github.com` auto-links), **not a write
  credential.** This killed a whole write-PAT + merge-gate design branch in plan-review (infra#174
  reduced to account-only). Credential-scoping angle belongs in infra's `open_work` memory
  (residency) — pending write; recoverable meanwhile from infra#174's body.
- **Rebase-merge (ADR-0016/0017) rewrites committer→merger**, so agent PRs *cannot* get clean
  contribution-graph separation under the mandated merge strategy — that's *why* graph-separation is
  a non-goal, not a bug to chase. Per-PR-type merge strategy was rejected: breaks the single-strategy
  invariant, destroys the "a human shipped it" signal, optimizes a vanity metric.
- **Amend, don't `-s`, for a partial-clause ADR change.** ADR-0037 amends *only* ADR-0035's
  shipped-work clause; 0035's named-identities decision stays Accepted and in-build (#540). `adr new
  -s <old>` stamps the *whole* old ADR Superseded — wrong at clause granularity. Instead: quote the
  exact clause, state the amendment in the new ADR's Context + why the prior reasoning changed, add a
  one-line amendment pointer to the old ADR. Candidate to graduate into the ADR README as durable doc.

See [[project-memory-pr-automation]] (ADR-0035/0036 lineage) and infra's `open_work` for the
credential-side lesson.
