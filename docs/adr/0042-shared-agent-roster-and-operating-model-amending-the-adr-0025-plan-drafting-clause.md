# 42. Shared-agent roster and operating model, amending the ADR-0025 plan-drafting clause

Date: 2026-08-14

## Status

Accepted

Amends ADR-0025's issue-stage plan-drafting clause only; ADR-0025 stays Accepted — its
PR-stage cross-model code reviewer is deliberately untouched.

Roster table amended 2026-08-16 by
[ADR-0046](0046-hosted-per-role-agent-memory-over-mcp-http.md): runtime homes
per the #582 topology (cloud surfaces, hosted legs, memory reach).

## Context

Epic #545 treats agents as managed team members rather than personal tools. Two shared agents
exist today — `backlog-manager` and `plan-reviewer` — and the PR code reviewer ships as a
non-Claude workflow (`scripts/pr-review/run.mjs` + `pr-code-review.yml`, ADR-0025). #560 asks
the next questions: which roles earn a shared agent, what pipeline they form, and what keeps
one role from quietly doing another's job.

Two forces make it a decision now rather than drift. ADR-0025 put implementation planning in
the backlog-manager deliberately — one session drafts, the isolated reviewer grades, and the
drafter can't wave its own plan through. Moving technical drafting out reverses that clause, so
it needs recording. And the roster's enforcement mechanisms — attributed in-thread turns, an
automatic architect⇄reviewer loop, per-role memory scoping — all need the event-driven
substrate (#576) and agent identity (ADR-0035, #540), both **UNBUILT**. Designing enforcement
for absent substrate is exactly the #545 principle 4 trap, so the design/build line is drawn
explicitly below.

Shaped 2026-08-12, plan-reviewed and grilled 2026-08-13 (#560). The reviewer's round-1 verdict
was rethink — it caught this re-deciding ground three accepted ADRs already held — and the
maintainer settled the four load-bearing forks before it firmed.

## Decision

### Roster

A role earns a shared agent only if it clears all three of #545 principle 3's gates —
structural edge (accumulated team memory, structural independence, or being the
artifact-of-record) × invocation fit (a natural invitation surface, human-gated, never
self-invoking) × latency-viable. That principle stays the criteria's one home; this is the
roster it produces.

| Role              | Status              | Edge                                                                                                      | Invocation                          |
| ----------------- | ------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `backlog-manager` | built               | grooming memory + artifact-of-record + cross-stakeholder intake funnel                                    | grooming ceremony / on-demand       |
| `plan-reviewer`   | built               | structural independence — a session can't adversarially review its own design                             | on-demand on a design               |
| code reviewer     | shipped, non-Claude | independence on a finished diff; cross-model by design (ADR-0025)                                         | PR review request                   |
| `architect`       | to build            | owns the technical-design lane, distinct from backlog-manager's what/why                                  | invited on plan-review tickets      |
| implementor       | in-session          | per-ticket judgment with no shared moat — #545 principle 5's exception, the `implement-issue` skill today | individually invoked                |
| `flow-manager`    | deferred            | lifecycle state machine, cadence, retros→backlog, sizing calibration                                      | no ceremony exists to invoke it yet |
| UAT / acceptance  | rejected            | no automatable acceptance surface in a solo dotfiles repo                                                 | —                                   |
| release-manager   | rejected            | no edge over git-cliff and `release-*.yml` (ADR-0004)                                                     | —                                   |

`flow-manager` is named for the function, not the ceremony — owning issue lifecycle and cadence
outlives scrum.

### Backlog-manager re-scoped, and what that amends

The backlog-manager owns intake, dedupe, relationships, cross-repo links, labels, priority, the
what/why/done, and the **readiness bookends** — gating ready-to-plan in and ready-to-implement
out. It no longer authors the technical plan; the `architect` does, in-ticket, on plan-review
tickets only. That is the ADR-0025 clause this amends.

ADR-0025's guard survives the move: the independent reviewer grades a plan with unresolved
blocking findings as not-approvable, so no author approves its own plan. It now guards the
architect's plan instead of the backlog-manager's.

The readiness labels re-expand ADR-0025's deliberate two-state protocol
(`needs-plan-review → plan-approved`, itself chosen over an earlier triad) to
`needs-grooming → ready-to-plan → in-design → plan-approved`. The triad-avoidance no longer
holds: with the architect owning a distinct in-design phase, `in-design` names a state a real
actor occupies rather than a bookkeeping stage.

### Pipeline and risk tiers

```text
backlog-manager             issue: what / why / done, deps, cross-repo links, labels
architect                   drafts the technical plan in-ticket (plan-review tickets only)
architect ⇄ plan-reviewer   converse in the issue thread until clean
backlog-manager             on clean convergence → ready to pick up
                            >3 rounds unresolved → STOP, block for a human decision
implementor → code reviewer code authored → critiqued (non-Claude, PR stage)
flow-manager                owns the execution lifecycle throughout (deferred)
```

Depth scales with risk — the tier is a backlog-manager triage call, the same judgment as
priority and the `architecture` label:

| Tier        | Path                                          | When                                                      |
| ----------- | --------------------------------------------- | --------------------------------------------------------- |
| Trivial     | backlog-manager → implementor                 | typo, config bump, one-liner                              |
| Standard    | backlog-manager → implementor → code reviewer | a contained feature; the implementor plans its own change |
| Significant | full relay, plus architect and plan review    | `architecture`-labeled, epic, wide or risky               |

The architect fires only on significant tickets, which is also what keeps cross-lane exposure
low by volume.

**Dead-man's switch:** more than three rounds without a clean plan stops the loop and blocks
the ticket for a human decision. It is the concrete instance of #545's loop-safety rule, and
the escape hatch for the fence below.

### The readiness/execution seam

```text
needs-grooming → ready-to-plan → in-design → plan-approved            READINESS (backlog-manager)
                                 └ architect ⇄ plan-reviewer loop
plan-approved → picked-up → in-progress → in-review → testing → done  EXECUTION (flow-manager)
```

The seam is `plan-approved`. Inside the design phase, state authority and content authority are
different agents: the backlog-manager owns transitions, the architect and reviewer own content.
Flipping `plan-approved` is a **procedural** judgment — "the reviewer reports no open blocking
findings" — never a technical one.

That fence is clean in the empty-findings case and blurs in the cases it exists for: a
contested finding, a human waiver, or "the approach itself is wrong." Those are content
judgments routed back to the architect and reviewer or to the human; the dead-man's switch is
the release valve.

### Lane-keeping

You cannot stop an agent seeing across lanes, so make it unable to _act_ or _keep_ across them.

Enforceable now, by structure and prose:

| Layer                      | Prevents                        | Mechanism                                                  |
| -------------------------- | ------------------------------- | ---------------------------------------------------------- |
| Separate context           | knowledge transferring silently | distinct agents and sessions — the handoff is the boundary |
| Role-owned body sections   | blurring on a shared surface    | who-writes-where is a checkable diff                       |
| Definition + negative rule | "I'll just do it myself"        | opinions route advisory, never execute — no write target   |

Blocked on substrate, and not a live control until it lands:

| Layer                       | Prevents            | Blocked on                                     |
| --------------------------- | ------------------- | ---------------------------------------------- |
| Attributed artifact channel | undetected creep    | agent identity (ADR-0035, UNBUILT)             |
| Scoped decision memory      | creep into the moat | per-role write-ownership (ADR-0043) + identity |
| Telemetry → definition edit | drift over time     | observability (UNBUILT)                        |

Two rules fall out. **Recommend versus execute:** the architect recommends a split, the
backlog-manager executes it — the same shape as propose-priority/human-disposes. **Invocation
is not context merge:** an invited agent returns its artifact, not its reasoning stream.

### Journaling

The issue is the substrate. The **body** is a self-contained current spec partitioned into
role-owned sections — Problem/Outcome/Acceptance are the backlog-manager's, Technical Design is
the architect's — so reading the top post is enough to implement. The **thread** is the
attributed real-time journal: the first approach, where the reviewer broke it, the retraction,
the fix. Artifacts consolidate into the body at `ready`.

### What is design, what is build

Firm now: the roster, the lane boundaries, the invocation model, the three-round loop-safety
rule, and the memory-tier contract (ADR-0043). Gated on the event-driven substrate (#576) and
agent identity (ADR-0035, #540): the automatic architect⇄reviewer loop, native reviewer
invocation, first-class in-thread agent turns, and per-role memory enforcement. Until the
substrate lands, the loop runs as hidden subagents with the backlog-manager posting attributed
digests — the interim already exercised on #159, #163, #170, #555, and #560 itself.

## Alternatives considered

- **Supersede ADR-0025 outright** — the framing #560 carried, and wrong by this repo's own
  amendment rule: 0025 decides two things, and its PR-stage cross-model reviewer stays live.
  Superseding marks the whole ADR dead to reverse one clause of it.
- **Keep plan-drafting in the backlog-manager** (ADR-0025 unchanged, the plan reviewer's
  simpler path) — one session drafting and reviewing is cheaper and already works. Rejected:
  the what/why lane and the technical-design lane want different memory and different
  invocation, and fusing them is what made the backlog-manager definition sprawl.
- **A Claude PR code reviewer as plan-reviewer's post-build twin** — rejected for ADR-0025's
  own reason: Claude reviewing Claude shares blind spots with the planner and implementor. The
  shipped non-Claude reviewer stands; model portability is #545 principle 8's separate track.
- **The architect as an in-session role** (#545 principle 5's implementor exception) — its
  critique is the plan-reviewer's job and its what/why is the backlog-manager's, so the edge
  looked thin. Rejected on the owner's call that a distinct technical-design lane with its own
  accumulated memory is the point; the thin-edge risk is real and named below.
- **Build `flow-manager` now** — deferred, not rejected: no cadence or ceremony exists in a solo
  repo to invoke it, so it would be a sock puppet on arrival.
- **Shelve the whole model until the substrate ships** — the reviewer's round-1 recommendation.
  Rejected because the causality runs the other way: this roster is the concrete justification
  for building the substrate, and #576 is filed against it.

## Consequences

The design is recorded before its enforcement exists, deliberately — nothing here presents
unbuilt capability as live, and every substrate-gated item is marked. The cost is a gap where
the model is prose discipline rather than a control, held by separate contexts and role-owned
sections until identity and the substrate close it.

Concrete follow-on work: create the `architect` agent and its plan-review entry criteria, strip
plan-authoring from the backlog-manager definition, add the readiness labels, wire native
invocation for both reviewers, and build per-role memory write-scoping (ADR-0043). All but the
definition edits are substrate-gated.

The named risk is the architect's: invoked only on significant tickets, it may not accumulate
enough memory to earn the moat that justified it — #545 principle 2's sock-puppet failure mode.
Revisit if the architect's memory stays thin after real use, if the three-round switch fires
often enough to read as a process smell rather than a safety net, or if the substrate work
lands somewhere other than #576 assumes.
