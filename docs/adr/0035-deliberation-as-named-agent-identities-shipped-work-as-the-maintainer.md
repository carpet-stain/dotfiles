# 35. Deliberation as named agent identities, shipped work as the maintainer

Date: 2026-08-10

## Status

Accepted

## Context

Agents author two kinds of GitHub-facing content here. Shipped work —
`/implement-issue`'s commits, PRs, code — is the maintainer's: he directs
it, reviews it, owns it, and `voice.md` makes it read as his. Deliberation —
backlog grooming, implementation plans, adversarial plan critiques — is not:
it's an agent's own reasoning, posted under his name, which `voice.md` can
only make _sound_ like him. That attribution gap is the problem (#510,
design conversation 2026-08-01).

What made fixing it feasible now: infra#119 moved machine secrets to AWS
SSM (uncapped accounts, OIDC/IAM — the Bitwarden three-account cap is
gone), and spike #395 verified that GitHub's reviewer-request API takes
only user logins — a GitHub App can post but cannot be requested as a
reviewer, @-mentioned as a participant, or appear as anything but
`name[bot]`. Participation requires machine-user accounts.

## Decision

Deliberation gets named agent identities; shipped work stays the
maintainer's. Concretely — each point confirmed in #510's deliberation
(2026-08-10):

- **Split by ownership.** Two machine-user accounts, one per deliberation
  role (backlog-manager, plan-reviewer). Grooming, plans, and critiques
  post under them. Commits, PRs, and code stay under the maintainer's
  identity; `voice.md` narrows to him and implementation content.
- **Invitation is the authorization.** Requesting plan-reviewer as a PR
  reviewer — or @-mentioning/assigning it on an issue, since the
  reviewer-request API is PR-only (#395) — is the human trigger; from
  there it grounds, critiques, and posts unattended. It never
  self-invokes. Backlog-manager stays human-steered per-session; only its
  attribution changes. Walk-back is "stop inviting it".
- **Orchestration runs locally.** Invitations are picked up on the
  maintainer's machine (in-session, or the repo-watch/cron path); agents
  post via their own SSM-vended credentials. No GitHub-hosted model
  runtime.
- **Voices are corpus-seeded and role-anchored.** Same method as
  `voice.md` (spike #474), per agent: distill from the agent's own real
  output (backlog-manager's authored issues, plan-reviewer's critique
  comments), codify the traits in that agent's definition file
  (`claude/agents/*.md`). Differentiation comes from role posture —
  verdict-first adversarial vs problem/acceptance-shaped PM — not
  cosmetic quirks.
- **Phased: who speaks, then when.** Phase 1 = identities exist and every
  deliberation post is attributed (accounts, `repos.tf` grants, SSM
  credentials, voices, `voice.md` narrowed) with the loop still
  in-session. Phase 2 = the exchange moves onto the issue (invitation
  trigger, local pickup, unattended reviewer, plan-review gate as
  alternating named comments on the thread).

## Alternatives considered

- **GitHub Apps as the identities** — an App can post but cannot
  participate: no reviewer requests, no plain @-mention presence, a
  `[bot]` suffix. #395 verified the API shape; participation is the whole
  point.
- **GitHub-Actions-driven orchestration** — fully event-driven, but parks
  a standing Anthropic API key plus each agent's PAT in Actions secrets —
  the standing-credential class the ADR-0010 arc just eliminated — and
  hangs model spend on GitHub events. Rejected for now; revisit only on
  observed latency friction (the same revisit-on-friction posture as the
  vended-token expiry decision). The cost of local is latency only: the
  loop can't finish while the maintainer is away regardless, since he
  flips `plan-approved` personally.
- **Fully human-gated posting** — a human approves every post, so the
  on-issue exchange degrades to manual relay; no honesty gain over
  today's in-session loop.
- **Both agents unattended** — backlog-manager acting on its own judgment
  without per-session steering is the posture that can't be quietly
  walked back; deferred, not adopted.
- **Attribution without voices** — accounts alone leave three flavors of
  the same writer; the named identities would read as sock puppets rather
  than participants.
- **Single unphased build** — longest time to any visible win; the
  attribution-only phase buys most of the honesty for a fraction of the
  build.

## Consequences

Deliberation threads read as what they are — named participants with
distinct voices, the maintainer deciding. `voice.md` stops stretching to
cover reasoning he didn't write. New costs: two accounts to bootstrap
(account/email/2FA are irreducibly manual; repo access is `repos.tf`
code; credentials live in SSM), two voice specs to maintain in the agent
definitions, and a Phase-2 pickup path to build. plan-reviewer stops
being read-only in effect — its structural independence (fresh context)
stays, but it gains a posting credential scoped to comments. Revisit
Actions-driven orchestration on observed latency friction; revisit the
backlog-manager autonomy line only deliberately, never by drift. The
implementation epic spawned from #510 tracks the build.
