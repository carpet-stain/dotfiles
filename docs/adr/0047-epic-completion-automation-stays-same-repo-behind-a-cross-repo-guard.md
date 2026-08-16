# 47. Epic-completion automation stays same-repo behind a cross-repo guard

Date: 2026-08-16

## Status

Accepted

Extends [40. Per-repo backlog with a virtual multi-repo project overlay](0040-per-repo-backlog-with-a-virtual-multi-repo-project-overlay.md)
(virtual membership affirmed — nothing in 0040 is reversed; this adds
the completion-automation reach decision 0040 didn't need to make).

## Context

dotfiles#592 wants a workflow that flags an epic for close the moment
`subIssuesSummary.percentCompleted` hits 100. Under ADR-0040 a
multi-repo epic's cross-repo membership is _virtual_ — enumerated from
`blocked-by`/`blocking` links and body `#`/URL references, never stored
as native sub-issues — so the summary can't see it: dotfiles#545 reads
100% complete with cross-repo work still open. A naive trigger
false-positives on exactly the multi-repo epics. Spike dotfiles#591
probed the capability boundary and decided the reach.

The probe (2026-08-16, GraphQL `addSubIssue` between throwaway issues
dotfiles#603 → project-starter-template#90, routine fine-grained token,
user — non-org — account; throwaways closed after, delete needs admin):

- **Native sub-issues cross repos under a user account.** The mutation
  succeeded with no org machinery involved.
- **`subIssuesSummary` counts native cross-repo children.** The parent's
  `total` included the cross-repo child immediately and closing it drove
  `percentCompleted` to 100. The spike's premise "the summary counts
  only same-repo sub-issues" is false for native links — the blind spot
  is _virtual membership_, not the repo boundary. #545 reads 100%
  because its cross-repo members are virtual, not because they're
  cross-repo.
- **Visibility:** every carpet-stain repo is public (verified
  unauthenticated, 2026-08-16 — the spike's "infra is private" premise
  was stale), so the probed public↔public pair matches #545's real
  pair. Mixed-visibility linking is unprobed; re-probe before relying
  on it if a private repo ever joins the fleet.

## Decision

1. **Reach: the #592 nudge stays same-repo-only.** Cross-repo
   completion detection stays with the backlog-manager's grooming sweep
   (ADR-0040's live enumeration) — the deterministic workflow never
   attempts it.
2. **Guard: skip any epic carrying a cross-repo membership signal.**
   The predicate: a cross-repo `blocked-by`/`blocking` link, or a
   cross-repo `#`/URL reference in the epic body — checkbox task-list
   or plain, either counts. Precondition: the guard's signal set is a
   superset of ADR-0040's cross-repo membership sources; if 0040 ever
   gains a membership source, the guard widens first. Err toward
   skipping — a missed nudge falls back to the sweep (status quo), a
   false flag is the failure this guards against.
3. **Membership stays virtual — ADR-0040 affirmed, not superseded.**
   The probe proves native cross-repo sub-issues are _possible_; they
   are still rejected as the membership mechanism (below).
4. **Markdown task-list epics: in the overlay, out of the nudge.**
   Body task-list references stay a membership source (0040 source b)
   and therefore a guard signal; the nudge never covers them — with no
   native sub-issue link there is no `subIssuesSummary` to read.

## Alternatives considered

- **Native cross-repo sub-issues as the membership mechanism** (the
  spike's path b) — capability-confirmed, rejected on cost:
  - **Single-parent constraint.** An issue has exactly one parent, so a
    cross-repo child already under its own repo's epic can't also be a
    native child of the multi-repo anchor. Virtual membership expresses
    overlapping membership; native parent-child structurally can't.
  - **The overlay is more than membership.** Priority derivation,
    cross-repo sequencing, and the project memory home all stay with
    ADR-0040's model regardless — native links would replace only the
    enumeration source, leaving a hybrid with more drift surface, not
    less machinery.
  - **Migration for a latency win.** Rewiring #545's link graph (and
    provisioning terraform-governed labels) buys only instant flagging
    over next-sweep flagging — a lag, not a correctness gap.
- **Widening the nudge to compute virtual membership in CI** —
  reimplements ADR-0040's recursive enumeration inside a workflow,
  which then drifts against the backlog-manager's authoritative
  traversal. Deterministic CI should read native fields, not maintain a
  second membership implementation.
- **No guard — trust `percentCompleted`** — false-flags every virtual
  multi-repo epic; #545 is the live counterexample.

## Consequences

dotfiles#592 ships same-repo-only with the guard as specified,
unblocked.
Multi-repo epic completion keeps sweep latency — accepted, bounded by
grooming cadence. The guard predicate is coupled to ADR-0040's
membership enumeration (the superset precondition); a change there is a
change here. Native cross-repo sub-issues stay a shelved, verified
capability — revisit if overlapping membership stops mattering or a
materialized board (0040's forward option) is built, and re-run the
probe rather than trusting this record if GitHub's sub-issue model has
had time to move.
