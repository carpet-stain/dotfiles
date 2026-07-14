# 15. Draft-PR-early, journal-via-comments, finalize-at-handoff

Date: 2026-07-12

## Status

Accepted

## Context

An agent session did all its exploration and discussion in chat, then produced
one Conventional Commit and one PR description at the very end — the reasoning
trail (gotchas hit, decision forks not taken, retractions, points the operator
flagged) died with the chat window (#125). The "why" was already split well on
the front end — the issue holds design and spikes (#123, #124) — but the back
end, how the implementation actually unfolded, had no durable home; that belongs
in the PR, which was opened too late and too finished to hold it (#125).

This fights the single-commit gate. The repo is rebase-merged (#107): the PR's
one commit lands on `main` verbatim, so AGENTS.md required squashing to one
Conventional Commit before opening the PR, and `pr-guards.yml`'s
`single-commit` + `conventional-commit` jobs fire on every `synchronize`.
Opening a PR early collides head-on: every WIP push fails both checks until the
final squash (#125). Under rebase-merge the single-commit gate is load-bearing
(it's literally what lands on `main`), so it can't just be dropped (#125). A
sharp edge shaped the fix: a required job skipped via a job-level `if:` reads as
passing to branch protection, so gating the checks on `draft == false` keeps WIP
quiet without hanging the required check — verified empirically against this
repo's branch protection, not assumed from docs (#125, #138).

Later an observed failure showed the codified rule still contradicted itself: an
agent editing verifiable markdown (#140) batched to one end-of-work commit
because git.md's "directly-verifiable work skips this" line gave it cover
(#147).

## Decision

Open a draft PR at the first commit for every change — verifiable or not — and
journal decisions, gotchas, forks, and retractions as PR comments while work
proceeds; the draft PR is the real-time record, not a postmortem.
`pr-guards.yml`'s `single-commit` and `conventional-commit` jobs are gated on
`draft == false` (with `ready_for_review` added to the triggers), so WIP pushes
stay quiet and the gate evaluates for real at ready-for-review (#125, #138).

`git pr` takes an explicit `--draft` flag rather than inferring intent from
ambient repo state, which was rejected as control flow that silently diverges
from operator intent (#125, git-pr-link.sh): `git pr --draft` opens the draft
(requires ≥1 commit ahead of `origin/main`, errors if a PR already exists), and
plain `git pr` finalizes an existing draft via `gh pr ready` — there is no
direct-to-ready path (git-pr-link.sh).

The agent finalizes — squashes to one Conventional Commit and marks the PR ready
— at handoff for all work: draft means the agent is still working, ready means
it's the human's turn (#158). For changes the agent can't confirm alone (GUI,
TUI, rendering, keybindings), the human's confirmation folds into reviewing the
ready PR rather than gating the flip (#158). Staying in draft at handoff is the
explicit, called-out exception, allowed only when the agent needs the human to
test something before code review (#158).

## Alternatives considered

- **Hold the PR in draft until human confirmation for unverifiable work**
  (#147/#148, the prior stance, superseded ~2h later by #158) — #147 scoped the
  exception to "hold off finalizing until confirmed" for GUI/TUI/rendering work,
  its stated reason being that each review round-trip on something unvalidated
  is real overhead (git.md at 7b0109e1). #158 reversed it: that reason assumes a
  separate reviewer to shield from WIP, but in this solo repo the reviewer and
  tester are the same person, so "ready" means "your turn to review and test"
  and the confirmation folds into review instead of gating the flip; finalizing
  also triggers pr-guards CI, so the human picks the PR up with checks already
  run (#158).
- **B — comments-only journal, zero CI changes, commit shape unchanged** (#125)
  — keeping the WIP-then-squash flow and journaling only through comments leaves
  every PR's required checks permanently red for its whole WIP lifetime;
  technically harmless (checks only block merge, not PR existence) but a
  standing cost across every PR under this workflow (#125).
- **Implicit detection — `git pr` inspects whether a PR already exists and
  branches on that** (#125, #138, git-pr-link.sh) — rejected as ambient-state
  control flow that silently diverges when the operator's actual intent doesn't
  match repo state. Instead each mode is an explicit flag (`--draft` to open, no
  flag to finalize) that asserts its own precondition and fails with a specific
  message (#125, #138).
- **Drop the single-commit / conventional-commit gate to allow early PRs**
  (#107, #125) — under rebase-merge the single-commit gate is load-bearing,
  literally what lands on `main` verbatim, so it can't be dropped; gating it on
  `draft == false` moves only its trigger point, not its strength (#125).

## Consequences

The PR becomes the durable journal: reasoning survives a closed chat, and a
reviewer sees the decision trail, not just the diff (#125). draft/ready is now a
clean handoff signal — draft = agent working, ready = human's turn — and
finalizing triggers CI, so the human picks up a PR with checks already run
(#158). Enforced by `pr-guards.yml`'s `draft == false` job gate (job-level
`if:`, verified not to hang branch protection — #138) and
`scripts/git-pr-link.sh`'s two explicit modes.

The finalize-at-handoff and open-early rules are prose-only nudges, not gates
(#147, #158) — if they prove unreliable, the forcing-function path is a
`git wip`/`git done` helper that commits + pushes + `gh pr ready` in one step
(#145), so the "first commit exists" and "finalize at handoff" triggers can't be
collapsed. git-pr-link.sh's finalize also fetches + rebases onto `origin/main`
and flips ready before pushing, because `ready_for_review` and the push's
`synchronize` event share a head SHA and GitHub evaluates draft-gated jobs once
per SHA (#172, git-pr-link.sh).

Revisit if the repo stops being solo (the finalize-at-handoff reasoning assumes
reviewer and tester are the same person) or moves off rebase-merge (which is why
the single-commit gate is load-bearing) — inferred from the premises the sources
name (#158, #125), not stated as an explicit revisit trigger.
