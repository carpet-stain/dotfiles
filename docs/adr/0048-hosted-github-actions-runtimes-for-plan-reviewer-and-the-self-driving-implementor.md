# 48. Hosted GitHub Actions runtimes for plan-reviewer and the self-driving implementor

Date: 2026-08-17

## Status

Accepted

Amends ADR-0035's local-runtime clause only; ADR-0035 stays Accepted.

Amends ADR-0046's roster runtime-homes block (the ADR-0042 amendment), extending it with a
hosted home for plan-reviewer.

Records Decision 2 (2026-08-16, maintainer-confirmed, see #582). Plan converged over two
plan-review rounds (#596).

## Context

ADR-0035 rejected GitHub-Actions-driven orchestration for two reasons: it parks a standing
credential class — an Anthropic API key plus each agent's PAT — in Actions secrets, and it
hangs model spend on GitHub events. It kept plan-reviewer and the implementor local, judging
the cost as latency only: the loop can't finish while the maintainer is away regardless, since
he flips `plan-approved` personally.

Two things changed that premise. ADR-0046 (merged) hosted per-role agent memory on Postgres
reached over MCP-over-HTTP, dissolving the reachability gate that kept runtimes machine-local —
a hosted runtime now reaches its own store the same way a local session does. And #598 designs
a self-driving implementor whose plan-review-gate loop runs unattended inside the hosted flow:
once that loop exists, "local costs only latency" stops holding for the role that participates
in it — the maintainer isn't gating every turn, only the merge.

This retires 0035's rejected Actions-driven-orchestration alternative, ADR-0037-style: not
because a new latency-friction trigger fired (0035's own named revisit condition), but because
the premise the rejection rested on no longer holds.

## Decision

- **Runtime: GitHub Actions first.** Event-native triggers — @-mention, review-request, labels
  — need no separate webhook infrastructure. FaaS is deferred, not built: revisit only if
  Actions' own limits (job duration, concurrency) bite in practice.
- **Credential model (answers prong a, honestly).** OIDC-vended short-lived credentials
  (Actions OIDC → SSM, ADR-0041's arc) relocate the standing-credential class out of Actions
  secrets into the SSM/vended model. They relocate it, not eliminate it: the Anthropic API key
  is irreducibly static, and each agent's PAT rotates on the same ~annual cadence as any other
  credential in `docs/credentials.md`. Named as an accepted, honest residual — the same
  "asymmetry accepted and named" move ADR-0046 made for cloud-surface bearer tokens. Per-role
  bearer tokens to the hosted memory endpoint follow ADR-0046's per-role-credential model
  (ownership by construction), not ADR-0043, which 0046 superseded.
- **Spend guardrail (answers prong b) — controls named by shape, numbers deferred to the build
  epic.** Three distinct, composing controls: an **in-run ceiling** (max turns / max tokens /
  wall-clock job timeout) as the fast runaway guard; a **billing alarm** as the slow backstop,
  firing on delay rather than in real time; and a **spend dead-man's switch** halting an
  unattended drain. All three compose with, never replace, ADR-0042's three-round loop cap.
  Fail-closed default: no cap configured means the workflow does not run.
- **Runtime write credential (the ADR-0038 interaction — decision A1).** The hosted
  implementor's PR-push flow would reverse ADR-0038's "the human is the only actor who can push
  or merge" safety property. 0048 does not amend 0038. The hosted-implementor leg is
  design-of-record, inert until #598: it activates only when #598 delivers both the write grant
  0038 already deferred and that grant's own precondition — the "push-not-merge ruleset
  expressibility" spike named in 0038's Alternatives. The ADR that takes up #598's grant is the
  one that amends 0038, not this one. Merge stays the maintainer's throughout, surviving both
  0035 and 0038; A1 and gating the push are consistent precisely because the write-bearing
  implementor isn't activated by 0048.
- **Identity.** #540's machine users — the reviewer-request API is user-logins-only (#395), so
  a GitHub App can't stand in. Git author per ADR-0038.
- **Roster homes — co-hosting ≠ co-activation.** Both plan-reviewer and the implementor move to
  hosted runtimes, but the implementor's activation is downstream of plan-reviewer's, gated on
  strictly more — ADR-0038's write grant plus the ruleset spike, on top of what plan-reviewer
  needs. The justification differs per role: the implementor needs unattended completion
  (#598); plan-reviewer moves because #598's plan-review-gate loop runs unattended inside that
  same flow — absent that loop, 0035's "local costs only latency" would still hold for
  plan-reviewer alone. plan-reviewer's own preconditions are the loop substrate (#576/#598),
  OIDC/SSM, and its existing `agent-gh` posting credential.
- **Flow.** The implementor opens a draft PR, journals, finalizes, requests review from the
  code-reviewer machine user, responds to and resolves threads (GraphQL `resolveReviewThread`),
  and re-requests via @-mention; plan-reviewer wakes on an issue @-mention. The human gates the
  merge throughout. Cross-role invocation is substrate-mediated, never an in-process subagent
  spawn (#545 principle 10 / Decision 3) — a nested subagent would run under the caller's
  credentials, defeating the per-role attribution and memory ownership ADR-0046 established.

**Survives 0035, reverses one clause.** Invitation-is-authorization, human gates the merge, and
the deliberation-identity / shipped-work split all survive untouched. What reverses is 0035's
local-only-runtime clause and its rejected Actions-driven-orchestration alternative.

**Not in scope.** The build itself: identities (#540), the hosted runner (#576), the
self-driving implementor (#598). 0048 is the decision record they build against — not a new
topology decision (ADR-0046's roster table already fixes that) and not the ADR-0036
`claude --agent` frontmatter amendment, which landed in ADR-0046 already.

**Infra prerequisite (committed, executed elsewhere).** An Actions OIDC provider plus
`/runtime/agent-*` SSM parameters reachable via OIDC — the same shape as 0035's SSM model,
infra ADR-0016 — recorded here as committed and executed outside this repo, the same posture
ADR-0046 took for its own infra prerequisites.

## Alternatives considered

- **FaaS instead of GitHub Actions** — functionally viable, but Actions is event-native with no
  separate infrastructure to stand up. Deferred behind a named revisit trigger (Actions' own
  limits), not built now.
- **Amend ADR-0038 now to grant the implementor a write credential** — would let the hosted
  implementor push unattended, but reverses 0038's human-only push/merge safety property before
  the ruleset spike (0038's own deferred precondition) proves push-not-merge is expressible.
  Deferred to #598; 0048 gates the write leg instead of granting it.
- **Keep plan-reviewer local, move only the implementor** — 0035's "local costs only latency"
  argument still holds for a human-gated reviewer in isolation. Rejected because #598's
  self-driving loop runs plan-reviewer's turn unattended too, inside the same flow — the
  argument stops holding for a role that participates in that loop.
- **Supersede ADR-0035 outright** — wrong relation per this repo's own amendment rule
  (`docs/adr/README.md`): 0035's other clauses — invitation-is-authorization, human gates the
  merge, deliberation-identity / shipped-work split — stay live. Superseding marks the whole
  decision dead to reverse one clause of it.
- **Bake concrete spend-cap numbers into this ADR** — the shape (in-run ceiling, billing alarm,
  dead-man's switch) is a design decision; the numbers are operational and belong to the build
  epic (#576/#598), tuned against real usage instead of guessed here.

## Consequences

Plan-reviewer and the implementor gain a hosted runtime, but nothing runs until the infra
prerequisite and the build epics (#540, #576, #598) land — 0048 is the design of record they
build against, the same posture ADR-0046 took for its own build epic. The hosted-implementor
write leg stays inert until #598 delivers both the ADR-0038 write grant and the ruleset spike;
co-hosting is not co-activation.

New risks that matter more once the loop runs unattended: event idempotency (webhook redelivery
risking a double post or double spend, dedup owned by the #576 build) and agent-definition-at-
runtime (which ref an Actions runner checks out — ADR-0039's agents-submodule plus the #597
repo-level `.claude/` gap). Loop safety (#545's invocation-gating: round cap, cycle guard,
budget dead-man's switch, halt-to-human) carries over unchanged but now guards an unattended
process instead of a locally-supervised one.

Revisit if: Actions' own limits bite (the FaaS trigger), a spend-guardrail threshold trips, or
the ruleset spike resolves — which is also what unblocks the ADR that takes up #598's write
grant and amends ADR-0038.
