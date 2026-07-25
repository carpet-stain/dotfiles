---
name: project-memory-pr-automation
description: Decision chain (2026-07-24) — whether/how to auto-merge git memory-pr's draft PR; gated on dotfiles#390 (gitleaks), tracked as dotfiles#411 (ADR-0027 amendment)
metadata:
  type: project
---

**Status: not yet decided, deliberately.** User asked for two things: (1) `git memory-pr` should
run `/audit-memory` automatically before opening the PR, (2) auto-merge the PR once opened. Both
collide with explicit, reasoned decisions already on record — flagged rather than implemented.

**Auto-merge was already considered and rejected once**, in ADR-0027's "Alternatives considered":
removes the human read-checkpoint that's the *only* coverage for secret-leak risk, since
`audit-memory` has zero secret-scanning capability. Not a style choice — the stated reason.

**Running `audit-memory` from inside backlog-manager's own `git memory-pr` call breaks the skill's
own design.** Its doc says explicitly: "Don't invoke it as the backlog-manager... the auditor is
not the author." Self-auditing your own memory write defeats the independent-read purpose. If this
gets automated at all, it has to be a separate process (e.g. a CI job on the PR, not the authoring
agent) — real infra work, not a script tweak.

**2026-07-24: user pointed out dotfiles#390 ("add gitleaks secret-scanning to lefthook + CI") is
already open and directly targets ADR-0027's named gap** — I'd missed it (found infra's ADR-0023
trivy/gitleaks-adjacent Terraform-scanning context instead and didn't cross-check dotfiles' own
backlog before answering the first time; corrected once asked). Agreed this is the right fix in
principle, bumped #390 to `priority: high`, and filed **dotfiles#411** (`architecture`-labeled,
`blocked` on #390) to do the actual ADR-0027 amendment once gitleaks lands — not done yet,
sequenced.

**Non-obvious mechanical detail, load-bearing for whoever implements #411:** `ci.yml` stays quiet
on draft PRs (`ready_for_review` gate, same shape as `pr-guards.yml`) — so gitleaks' CI copy won't
fire on the draft `git memory-pr` opens. The check that actually protects this flow is gitleaks'
**lefthook pre-commit** copy, firing inside `backlog-memory-pr.sh`'s own `git commit` step
(confirmed lefthook hooks do run there — watched `envrc-local-example-sync` fire on my last two
memory-sync commits). #411 says to verify this explicitly (plant a test secret, confirm the local
hook blocks it) before trusting it as the auto-merge gate — don't assume CI ran just because it
exists in the repo.

**Still an open question, not resolved by gitleaks:** `audit-memory` (staleness/duplication/
regression against live GitHub state) has no automated equivalent — gitleaks covers secrets only.
#411 point 4 asks the user to decide explicitly what happens to that checkpoint once auto-merge
lands, rather than letting it get silently dropped as a side effect of solving the secret half.
Don't assume it's been answered — check #411's state/comments for the actual decision before
building on it.
