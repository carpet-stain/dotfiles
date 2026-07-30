---
name: implement-issue
description: >-
  Worker-session ritual for implementing a single shaped GitHub issue end to end: verify it's
  ready, branch and open a draft PR, implement exactly what the issue's top post specifies,
  journal deviations from the plan, write terse, and hand off a ready-for-review PR whose body
  stands alone. Use when asked to implement, build, or work a specific issue number in a fresh
  session with no other context. Points at the repo's own git workflow for all branch/PR
  mechanics — doesn't restate them.
---

# Implement Issue

A thin wrapper around "go implement the spec." The mechanics of branching, committing, and
opening PRs live in the repo's own git workflow doc — this skill doesn't restate them.

## Steps

1. **Resolve the issue.** `gh issue view <N>`. Confirm it's OPEN — a closed issue is a shipped
   record, not something to reopen and build on. If the repo runs a plan-review gate (look for
   `needs-plan-review`/`plan-approved` labels or a stated convention in AGENTS.md), confirm it's
   `plan-approved` before starting; if the gate exists and the issue isn't approved yet, stop and
   say so instead of improvising a plan.
2. **The top post is the spec.** Implement what's written there — not an improvisation on it, not
   a redesign. If something in the spec turns out to be wrong or impossible, say so and stop
   rather than silently deviating.
3. **Follow the repo's own git workflow for mechanics.** Branch, open the PR in draft as soon as
   the first commit exists, commit freely, squash to one commit when ready, finalize. Read
   AGENTS.md (or CONTRIBUTING, or an equivalent stated doc) for the repo's concrete commands and
   conventions; absent one, fall back to the generic short-lived-branch-plus-protected-main model.
   Zero mechanics restated here — this step is a pointer, not a protocol.
4. **Tie the PR to the issue.** PR body carries `Closes #<N>`. Journal _deviations from the
   issue's plan_ specifically as PR comments while working — that's the signal a plan-vs-diff
   check reads later.
5. **Write terse.** Code comments explain why, not what; detail belongs on the issue, not in the
   diff. The PR description and comments stay terse by the same discipline.
6. **At finalize, hand off.** Apply the repo's PR handoff rule if it states one (self-sufficient
   top post, journal as optional depth) — rewrite the PR body to stand alone before flipping ready.
   Stop there. Flipping the PR to ready-for-review is the handoff; merging is someone else's call.
