# 51. Hosted event-driven agent-invocation substrate, PoC runner mechanics

Date: 2026-08-22

## Status

Accepted

Records #576's converged, plan-approved design (plan-reviewer rounds 1-2, F1/F2 folded in). Builds
on [ADR-0048](0048-hosted-github-actions-runtimes-for-plan-reviewer-and-the-self-driving-implementor.md)
(runtime, credential model, spend-guardrail shapes) and reuses [ADR-0042](0042-shared-agent-roster-and-operating-model-amending-the-adr-0025-plan-drafting-clause.md)'s
three-round loop cap. Capped to what the PoC (`.github/workflows/agent-runner.yml`,
`.github/agent-routing.yml`, `scripts/agent-loop-guard.mjs`) exercises, per #576's own scope guard —
not the full surface-agnostic runner or the architect build.

## Context

[ADR-0025](0025-advisory-review-pipeline-plan-gate-and-pr-code-review.md)'s plan gate
(`needs-plan-review` -> `plan-approved`) runs today entirely in-session: a maintainer's
`claude --agent backlog-manager` grooming session drafts, hands off to a nested `Agent(plan-reviewer)`
subagent, and loops. ADR-0048 moved both roles to a hosted GitHub Actions runtime once #598's
self-driving implementor made "local costs only latency" stop holding for a role that participates
in an unattended loop, and Decision 3 (#582) retired the nested-subagent-plus-digest interim:
cross-role invocation is substrate-mediated always, so the reviewer's turn has to be a separate,
first-class, invitation-triggered session under its own identity, not a subagent call inside the
drafter's process. This ADR designs that substrate's PoC mechanics.

Two gaps surfaced while implementing, neither visible from the plan text alone:

- **plan-reviewer's tool surface (`Read, Grep, Glob`) has no GitHub-reading tool.** "The reviewer
  posts its critique directly as issue comments" (the plan's own words) does not mean the agent
  calls `gh` itself — it structurally can't, and giving it one would be an agent-definition change
  (application code, out of this spike's scope). The runner supplies the issue thread as prompt
  context instead ("thread = journey" from the plan, fed in rather than fetched) and posts the
  session's stdout as the comment on the agent's behalf, authenticated as that role's own PAT — the
  comment still attributes to the machine user; only the mechanics of getting there differ from a
  literal reading of "posts directly."
- **The OIDC-assumed role built for this (`dotfiles_hosted_runtime_read`, infra#217) only granted
  `ssm:GetParameter` on the two `*-anthropic-key` parameters, not the two `*-pat` parameters or
  `vended-token`.** infra#217 was scoped to "read the Anthropic keys" specifically (its own title);
  the PAT read path the converged plan assumes ("the runner delivers the machine-user PAT +
  Anthropic key via Actions OIDC->SSM") was never built. Confirmed by reading `iam/main.tf` and
  BOOTSTRAP.md §14 directly, not inferred from the issue text. Filed as
  [infra#303](https://github.com/carpet-stain/infra/issues/303) (both PATs + vended-token);
  [infra#304](https://github.com/carpet-stain/infra/pull/304) landed the PATs, and a re-filed
  [infra#305](https://github.com/carpet-stain/infra/pull/305) landed the vended-token grant.
- **The two per-role Anthropic keys infra#217 provisioned had no credit balance.** Discovered live,
  on gate-0's first real spawn attempts (both `backlog-manager` and `plan-reviewer` failed with
  "Credit balance is too low") — not a design flaw, an unfunded-key gap. Rather than fund those two
  keys directly, the maintainer already has a funded OpenRouter account and chose to route through
  that instead: OpenRouter exposes an Anthropic-Messages-API-compatible endpoint (its "Anthropic
  Skin", `https://openrouter.ai/api`) that Claude Code's `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`
  can point at directly, verified live against OpenRouter's own docs, not assumed. See Decision.
- **`GITHUB_TOKEN`-authored mutations never trigger a new workflow run.** Caught by PR review, not
  the initial build: GitHub documents that events produced by the default `secrets.GITHUB_TOKEN`
  are excluded from triggering further `pull_request`/`issues`/etc. workflow runs (the built-in
  anti-recursion behavior) — with the sole exceptions of `workflow_dispatch`/`repository_dispatch`.
  The first draft of this runner used `GITHUB_TOKEN` for the turn-signal label flip specifically
  _because_ its actor is never a machine-user login, reasoning correctly about the recursion filter
  while missing that the flip would never re-fire the workflow at all — silently stopping the loop
  after one turn. Neither role's own PAT is a fix either: both machine users are `read` collaborators
  (ADR-0021), and GitHub label mutations need triage+ regardless of token type. See Decision.

## Decision

**Four deterministic pieces, LLM strictly the judgment layer (#545 principle 9).**

1. **Trigger.** Actions `issues` (`labeled`/`unlabeled`) and `issue_comment` (`created`) — the
   invitation is the event; labels are the reconstructed state, not a webhook or poll.
2. **Routing — `.github/agent-routing.yml`.** A written, versioned event+label -> role map; the
   workflow reads it, no model decides routing. Hand-rolled parsing (`scripts/agent-loop-guard.mjs`'s
   `parseRoutingConfig`) over a real YAML library: the config's shape is deliberately flat and this
   repo carries no JS dependency manager to vendor one for a single file.
3. **Loop safety — `scripts/agent-loop-guard.mjs`, no LLM.** A single new label,
   `awaiting-plan-critique`, is the turn signal: present = plan-reviewer's turn, absent (with
   `needs-plan-review` still open) = backlog-manager's turn. It is **runner-owned** — only
   `agent-runner.yml`'s own credential flips it, never a role's PAT (the vended-token point below
   under Spawn explains which credential, and why) — which is what exempts its labeled/unlabeled
   events from the recursion filter _by construction_: their actor is never a machine-user login,
   so F1's "actor equals the role this event would spawn" check can't match them, with no separate
   exemption list to maintain (F2). Round count is the number of times that label was **added** (a
   GitHub Timeline `labeled` event count), never a raw comment tally — the reviewer's own turn may
   post more than one comment. The cap reuses ADR-0042's three rounds, evaluated pre-spawn: round 3
   still runs, round 4's routed event is dropped with `spawn=false`, halting to a human rather than
   failing quiet. `round_cap` absent in the config is a hard error, not a default (ADR-0048's
   fail-closed rule).
4. **Spawn.** `claude -p --agent <role> --max-turns 8 --permission-mode bypassPermissions`, one
   session per invitation, each its own workflow run. Credentials: a shared OpenRouter key
   (`ANTHROPIC_BASE_URL=https://openrouter.ai/api` + `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY`
   cleared — not the two per-role Anthropic keys infra#217 provisioned, see Context) and the role's
   PAT, both OIDC->SSM (`vars.AWS_HOSTED_RUNTIME_ROLE_ARN`), the PAT verified against the expected
   `carpet-stain-<role>` login before use (mirrors `scripts/agent-gh.sh`'s own check, ADR-0038).
   backlog-manager's definition is submodule-only (ADR-0039), so its turn
   additionally checks out `claude/global` and symlinks `backlog-manager.md` into `.claude/agents/`;
   plan-reviewer's already lives there, so its turn is a plain checkout. The session's own stdout is
   posted as the issue comment under the fetched PAT — never `GITHUB_TOKEN`, since attribution to the
   machine user's own account is the point (ADR-0038/#540). backlog-manager's turn additionally
   passes `--disallowedTools "Agent"`, an attempted structural mitigation against its frontmatter's
   `Agent(plan-reviewer)` tool reproducing the retired nested-subagent interim — attempted, not
   verified: whether a CLI-level deny overrides an `--agent`'s own frontmatter tools list is
   undocumented upstream as of this writing, and gate-0 never spawns backlog-manager. See
   Consequences.

**The turn-signal flip rides the vended token (infra's `vend-token.yml`, a GitHub App installation
token), not `secrets.GITHUB_TOKEN`.** `GITHUB_TOKEN`-authored mutations are documented to never
trigger a new workflow run, which would silently stop the loop after the first turn (see Context);
neither machine-user PAT can label at all (`read` collaborators, ADR-0021, labeling needs triage+).
The vended token triggers downstream runs the way a PAT does and authenticates as neither role's
login, giving the exemption-by-construction property the design always wanted, on a credential that
actually has it. Precedented: `aws_iam_role.pst_e2e_read` already grants an OIDC role read on this
same parameter for a different consuming repo. Needed its own OIDC grant — asked for alongside the
PAT grant in infra#303, landed in [infra#305](https://github.com/carpet-stain/infra/pull/305) once
infra#304 shipped the PAT half only. The OpenRouter key (Decision point 4) rides a third grant on
the same role, [infra#311](https://github.com/carpet-stain/infra/pull/311), which also removed the
now-unused grants on the two per-role Anthropic-key parameters rather than leaving them orphaned.

**One-writer** is `concurrency: {group: issue-<number>, cancel-in-progress: false}` — GitHub-native,
no custom bookkeeping. **Spend ceiling** is `--max-turns 8` plus a 15-minute job `timeout-minutes`,
both always set (ADR-0048's fail-closed default is satisfied by construction, not by a runtime
check). **Overhead measurement (proof 1, #576)** is four wall-clock timestamps around the spawn
step — dispatch start, pre-spawn, post-spawn, post-processing end — reported as
`setup_ms + post_ms`, deliberately excluding the model-inference span between pre- and post-spawn.
The runner posts comments and flips one label; it never pushes or merges — ADR-0038's human-only
write property is untouched.

## Alternatives considered

- **A raw comment count as the round signal** — rejected per the plan's own F1/#5 finding: the
  reviewer may post more than one comment in a turn, so a tally over- or under-counts. A label-add
  count is exact because the runner alone controls when it fires.
- **A blanket "drop any machine-user-authored event" recursion filter** — rejected (F1): it would
  also drop the reviewer's turn-ending event before the drafter's next round could ever fire,
  collapsing the loop to human-only advancement at the full multi-role substrate. Scoping the filter
  to "actor equals the role this specific event would spawn" is both correct and, by making the
  turn-signal flip runner-owned, needs no separate exemption list (resolves the F1 nit about the
  login list being a maintenance seam).
- **Give plan-reviewer a `gh`/GitHub-reading tool so it can fetch the thread itself** — rejected:
  that is an agent-definition change (application code), explicitly out of this spike's scope, and
  it would erode the read-only guarantee ("Write/Edit aren't in your tool surface... a structural
  guarantee") the role's own definition states as load-bearing. Feeding the thread into the prompt
  keeps that guarantee intact while still satisfying "thread = journey." Whether that guarantee
  should eventually loosen is tracked separately, not decided here:
  [carpet-stain/agents#27](https://github.com/carpet-stain/agents/issues/27).
- **`secrets.GITHUB_TOKEN` for the turn-signal flip** — the original design (see Context): correct
  about the recursion filter, wrong about GitHub's own anti-recursion behavior on the token itself.
  Rejected once caught in PR review; replaced by the vended token (Decision).
- **Detect the reviewer's converge/block verdict automatically and auto-flip `plan-approved`** —
  rejected: #576's own framing is explicit that the human still gates the merge and flips
  `plan-approved` personally, regardless of what the runner automates. Auto-detecting convergence
  would also need a machine-parseable verdict marker in the reviewer's output — an agent-definition
  change this spike doesn't make. The round cap alone is the loop's dead-man's switch; a human
  reading the thread decides when it's done.
- **Ship gate-0's live smoke test as part of this ADR's evidence** — not possible: the credential
  gap in Context blocks any run. Named as a real limitation (Consequences), not worked around by,
  e.g., a standing PAT in Actions secrets, which is precisely ADR-0035's rejected residual.
- **Fund the two per-role Anthropic keys directly instead of switching to OpenRouter** — the
  originally-designed path (infra#217), and still viable. Not taken because the maintainer already
  has a funded OpenRouter account and explicitly chose to reuse it (see Context) — a credential-
  source preference, not a defect in the direct-funding design. Revisit if OpenRouter's Anthropic
  Skin proves unreliable for Claude Code's agentic tool-use/thinking features in practice.

## Consequences

**What this proves:** the routing/loop-safety/spawn mechanics are designed and unit-tested
(`scripts/agent-loop-guard.test.mjs` covers routing resolution, the recursion filter's scoping, and
the round cap's boundary) against the actual, live-verified state of `iam/main.tf`,
`.claude/agents/`, and this repo's label taxonomy — not a re-statement of the issue's own plan text.

**What this does not prove yet:** neither of #576's two required proofs (added-overhead measurement,
dead-man's-switch-survives-restarts) has a live data point. All three credential grants this ADR
needs are landed (infra#304 the PATs, infra#305 the vended-token, infra#311 the OpenRouter key) or
in review with `tofu plan` verified clean (infra#311, pending the maintainer's `tofu apply` and
`vars.AWS_HOSTED_RUNTIME_ROLE_ARN` seeding — both outside this repo's own credential scope, per
BOOTSTRAP.md §14). Overhead measurement is instrumented (four timestamps around the spawn step,
Decision) and will produce a real number the first time a spawn actually runs; it just hasn't yet.
`--permission-mode bypassPermissions`, the exact `claude -p` flag surface, and OpenRouter's
Anthropic-Messages-API compatibility for a headless `--agent` invocation specifically (verified for
interactive Claude Code, not for this exact spawn shape) are correspondingly unverified against a
real headless run — the ADR-0025 permission-mode landmine this spike's own investigation order
names as gate 0's job to retire.

**Named as future, not designed:** the architect role (unbuilt, ADR-0042 roster) and any pairing
other than backlog-manager/plan-reviewer; hosted per-role memory over MCP from this runner
(ADR-0046 names it unbuilt; both roles run memoryless here, faithfully for plan-reviewer, as a
stand-in for backlog-manager); an invocation-chain-marker cycle guard beyond the round cap (moot at
two roles in strict ping-pong — relevant once a third role can be invited mid-loop); FaaS as an
Actions alternative (ADR-0048's own deferred trigger, unchanged here).

**A risk mitigated, not verified:** backlog-manager's frontmatter (submodule-owned, out of this
repo's write scope) still carries `Agent(plan-reviewer)` for its local grooming-session use. The
runner now passes `--disallowedTools "Agent"` on backlog-manager's spawn (Decision) as an attempted
structural guard against a headless `claude -p --agent backlog-manager` invoking that nested
subagent mid-turn, which would reproduce the digest-relay interim Decision 3 retired — but whether
a CLI-level deny actually overrides an `--agent`'s own frontmatter tools list is undocumented
upstream, and gate-0 never spawns backlog-manager, so this is unverified either way. Tracked as
[carpet-stain/agents#28](https://github.com/carpet-stain/agents/issues/28); revisit before
backlog-manager's turn is ever spawned for real.

**Revisit if:** infra#311 lands and applies, and a live run either confirms or breaks an assumption
named above (the `claude -p` flags, OpenRouter's Anthropic-Skin compatibility with headless
`--agent` spawns, the `--disallowedTools` override behavior, the prompt-injection approach, the
label FSM); the round cap or spend ceiling values prove wrong in practice; or the backlog-manager
nested-subagent mitigation above is observed not to hold.
