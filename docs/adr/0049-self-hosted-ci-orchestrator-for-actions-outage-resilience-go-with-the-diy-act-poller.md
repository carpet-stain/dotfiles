# 49. Self-hosted CI orchestrator for Actions-outage resilience: go with the DIY act-poller

Date: 2026-08-17

## Status

Accepted

Spike: #629, four gates recorded there (#628 for gate 1's own spike). This ADR records the
decision the gates converged on, not the gate work itself.

## Context

The Aug 2026 Actions outage blocked merges for hours: required checks couldn't report, and
branch protection has no failover logic. Self-hosted runners don't fix this — they still poll
Actions' control plane for job assignment, so an orchestrator outage idles them too. Only owning
the orchestrator decouples us.

This repo is public, so hosted runners are free — this is purely a resilience play, not cost.
We already run our exact workflows under `act` (`scripts/act-run.sh`, `just act`), so the compute
half of an orchestrator already existed; the missing half was a trigger (poll PRs) and a
report-back (post statuses).

Scope: this only covers Actions-specific degradation. A full GitHub outage (git backend + API +
PR UI dark) blocks merges regardless — no orchestrator helps, and this decision doesn't claim to.

## Decision

**Go with Variant 2a — a DIY act-poller**, not Variant 2b (a real orchestrator like
Woodpecker/Forgejo). 2b duplicates every workflow as a second CI definition that drifts, and
wants a public webhook endpoint plus TLS. 2a reuses this repo's workflows verbatim through `act`
and needs no inbound ingress.

Shape:

- Always-on box: a small x86 VPS (Hetzner CX22 class, ~€3.79/mo) — x86 to match `ubuntu-latest`,
  since box uptime is the resilience being bought here.
- A systemd-timer poller (~100 lines): `gh api` open PRs → per new head SHA, run
  `act pull_request` → post per-job commit statuses.
- Polling, not webhooks — no inbound ingress/TLS, smaller surface, and a retry beats a webhook
  lost during degradation.
- Scoped PAT (`statuses:write`, `pull_requests:read`, `contents:read`) via the vended-token
  pattern (ADR-0041) — no Administration scope on the box.
- Scope: only the merge-gating checks (`ci/lint`, the three `pr-guards`, `adr-guard`,
  `e2e-linux`). `pr-code-review` (advisory) and `release-*` (manual) stay on Actions untouched.

The four gates from #629, and how each resolved:

1. **Failover semantics (#628) — GO.** A same-name external commit-status satisfies a required
   branch-protection context, confirmed empirically against a real PR (#631) under branch
   protection. Failover is viable, not just replace-only. Caveat: the collision case (external
   status vs. a same-named Actions check-run, which one wins when both exist) wasn't verified —
   that test's findings were lost before being recorded. Open follow-up, not blocking the go
   decision, since the simple case (no Actions check-run in play) is what an outage actually
   looks like.
2. **act fidelity on `e2e-linux` — GO.** Ran the real workflow under `act` from a plain clone
   against real merged-PR data (#614). On native arm64 (no emulation): checkout, both
   `dorny/paths-filter` runs (API-backed), submodule fetch, and `actions/cache` all succeeded —
   the three components this gate asks about. It failed afterward only on an unrelated
   `binaries.lock` gap (no pinned aarch64 Neovim entry), an artifact of the wrong test CPU arch,
   not an act/Actions fidelity gap. Forcing `--container-architecture linux/amd64` to also
   exercise the full `deploy.sh` on the real target arch hit two different Go-runtime panics at
   the same step under QEMU emulation — read as emulation instability, not a real divergence. A
   clean full-arch run needs real x86_64 hardware, not Mac+QEMU; not pursued, since it's outside
   what this gate asks (fidelity of `container:`/`paths-filter`/`actions/cache`, which is
   confirmed).
3. **Uptime inversion — moot.** Only mattered on the replace-only path (gate 1 NO-GO). Gate 1
   came back GO, so the box is never the sole gate for a merge.
4. **Public-repo fork security — design constraint, not yet build-verified.** The poller must
   filter to same-repo PRs only (`head.repo.full_name == base.repo.full_name`) before running
   `act` against any PR's code, and the box holds only the scoped PAT above — no other secrets.
   Binding on whoever implements this; unproven until built.

## Alternatives considered

- **Variant 2b — Woodpecker/Forgejo (a real orchestrator)** — rejected. Duplicates every workflow
  as a second CI definition that drifts from the Actions original, and needs a public webhook
  endpoint plus TLS, a larger attack surface than polling. 2a reuses the same workflow files
  verbatim through `act`; prefer it unless 2a proved infeasible, which it didn't.
- **Don't (stick with hosted runners, sanctioned admin-bypass during an outage)** — rejected once
  gate 1 came back GO. Kept as the fallback if the collision-case follow-up (gate 1's open item)
  comes back badly, or if the build (below) surfaces a blocker gate 1/2's cheap tests couldn't
  see.
- **Self-hosted runners instead of an orchestrator** — rejected in scoping this spike (see
  Context): runners still poll Actions' own control plane for job assignment, so an Actions
  outage idles them too. Doesn't solve the actual failure mode.

## Consequences

This is the design of record for Variant 2a — the build itself (provisioning the box, writing
the poller, minting the scoped PAT, and a live end-to-end proof: one real PR gated by a
self-hosted status) is separate, tracked work, not covered by this ADR landing. It carries real
infra spend and a live security surface (gate 4's constraint), so it enters this repo's
plan-review gate on its own rather than following automatically from this decision.

Two open items carry into that build, not blocking the go decision but binding on it:

- Confirm the collision case from gate 1 (external status vs. same-named Actions check-run, which
  wins) before the poller ships — Variant 2a's failover design assumes clean resolution and that
  specific case is unverified.
- Prove gate 4's fork-security constraint at build time (same-repo-branches-only trigger, PAT
  scope, no other secrets on the box) — recorded as a requirement here, not yet tested against
  running code.

Revisit if: the collision-case follow-up comes back NO-GO (branch protection can't cleanly
failover when both an Actions check-run and an external status share a context), or if the build
surfaces a blocker gates 1–4's cheap tests couldn't see.
