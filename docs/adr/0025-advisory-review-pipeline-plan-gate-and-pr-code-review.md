# 25. advisory review pipeline: issue-stage plan gate + pr code review

Date: 2026-07-18

## Status

Proposed

## Context

Epic #302 wants advisory review help across the issue and PR stages. The
first cut put a single Claude reviewer on the PR and kept planning
in-session. Iterating it surfaced a better decomposition and two more
goals.

The decomposition: reviewing a _plan_ on the PR is too late — by then the
code is written, so the reviewer's most valuable output ("this whole
approach is wrong") lands after the expensive part. Catch design problems
at the **issue stage**, before implementation; review the diff at the **PR
stage**, after. Different jobs — the #300 `plan-reviewer` subagent is
deliberately plan/architecture-only, so a separate PR-stage code reviewer
isn't redundant.

The two goals: run implementation on the **cheapest** model the governance
can carry, and get a **different model's** eyes on the code than the one
that planned it — cross-provider diversity, added where it's cheap.

The governing constraint stays #298's: borrow mechanisms, reject heavy
runtime infra; whatever this adds stays advisory (never gates a merge),
cheap, and controllable by one maintainer.

Facts as of 2026-07 (verified against code.claude.com/docs and vendor
docs, not recall):

- Claude Code runs Anthropic models only — a subagent's `model:` can't
  name a non-Anthropic model, and `ANTHROPIC_BASE_URL`/gateways change
  where a request goes, not which vendor answers. So any non-Anthropic
  reviewer lives _outside_ a Claude Code subagent.
- A required LLM check must _succeed_ to merge, so it hard-blocks on a
  rate-limit, outage, or false positive. Anthropic's own managed Code
  Review deliberately concludes "neutral" so it never blocks — strong
  evidence to keep any LLM reviewer advisory.
- Non-Anthropic PR-review Actions exist and are model-configurable (the
  OpenAI-based CodeRabbit OSS action, other OpenAI reviewer Actions), all
  advisory by default.

## Decision

Split the reviewer by stage; both advisory.

**Issue stage — plan gate, run from a dedicated grooming session.** No CI
here at all; the gate lives entirely in a long-lived `claude --agent
backlog-manager` session — the maintainer's single, resumable home for
issue work. An issue can enter the backlog from anywhere (the maintainer,
a human via the web, another repo's agent), so **triage is the single
choke point every issue funnels through**, whatever its source. The
backlog-manager reads triage state from live labels, not memory: it
already requires every issue to carry a type and a `priority:` label, so
an open issue **missing `priority:` is by definition untriaged** — the
grooming queue is the open issues without it, no `needs-triage` marker (or
the workflow to stamp one) needed. Triaging classifies type + priority
and, for feat/enhancement/epic (not fix/chore/docs; spikes are exempt — a
spike _is_ the plan work), applies `needs-plan-review` in the same pass.
Then the backlog-manager drafts the implementation plan onto the issue,
hands it to the `plan-reviewer` (#300), reads the critique, and loops with
the maintainer until the plan is sound — flipping `needs-plan-review` →
`plan-approved`. Implementation waits for `plan-approved`; a rejected plan
goes back to drilling the issue down. Because the backlog-manager runs as
the main thread there, it carries a scoped `Agent(plan-reviewer)` tool for
that hand-off, and the `plan-reviewer` still runs in its own isolated
context — one session drives both draft and review without losing fresh
eyes. This broadens the backlog-manager's lane from pure issue-management
to issue-level implementation planning — and the reviewer grades an
unresolved-blocking-findings plan as not-approvable, so the drafter can't
wave its own plan through. The gate is advisory discipline, not a hard
block: the labels are a queue and a signal, nothing mechanically stops
coding an unapproved issue — in keeping with everything else here.

**PR stage — code review by a _different_ model, advisory.** The plan
already got Claude's judgment in-session, so the diff gets a non-Anthropic
model's eyes — the independent perspective a Claude-reviews-Claude loop
can't give, catching blind spots shared with the planner and implementer.
A model-configurable advisory review Action (the OpenAI-based CodeRabbit
OSS action, or similar) runs on the PR and posts comments; it is **never a
required status check**. Claude Code can't host a non-Anthropic model
itself, but this stage is decoupled CI, so the reviewer is just a
different Action — the cheapest, cleanest place to put model diversity.
It's the CI counterpart to the local `/code-review` skill run pre-push.

**Model tiers — cheap under governance, premium at the judgment points.**
The implementer (a fresh session on a `plan-approved` ticket) runs on the
cheapest model, **Haiku 4.5** (`claude --model
claude-haiku-4-5-20251001`): the approved plan carries the judgment, so
execution under this governance is the mechanical part. The `plan-reviewer`
is pinned to **Opus 4.8** (`claude-opus-4-8`) — the adversarial catch is
where the top model earns its cost — and the `backlog-manager` (plan
_drafting_) to **Sonnet** (`claude-sonnet-5`), a cheaper draft the Opus
reviewer then grades. Set via each subagent's `model:` frontmatter, which
wins over `--model` when the agent runs as the main thread through `claude
--agent`. The PR reviewer's model is the review Action's own.

**Credential + cost — one manual repo secret, for the PR reviewer only.**
The PR review Action needs its model provider's key (e.g. `OPENAI_API_KEY`)
as a repo secret, added once by hand like `RELEASE_PAT` (ADR-0007). No
`ANTHROPIC_API_KEY` in CI: the plan gate runs in-session on the
maintainer's own Claude auth, and the implementer is a normal local
session. Advisory review on the diff is a few cents per PR, not worth
metering.

**Advisory, never required.** Gate a merge on _human_ approval (one
approving review, which the maintainer gives), not on the bot. A required
LLM check hard-blocks every merge on a rate-limit, outage, or false
positive — so review stays warn/suggest; deterministic checks stay the
blocking gate.

This re-scopes the build children: **#304** becomes the PR-stage
non-Anthropic advisory code reviewer (a model-configurable review Action +
its provider key); **#305** becomes the issue-stage plan gate — entirely a
backlog-manager change (no CI): its scoped `Agent(plan-reviewer)` tool, the
triage → `needs-plan-review` → draft → review → converge orchestration, and
the `needs-plan-review` → `plan-approved` labels.

## Alternatives considered

- **One reviewer, on the PR only** (the first cut) — rejected: it reviews
  the plan too late, after the code exists. Splitting plan review to the
  issue stage is the whole point of catching design problems before
  implementation.
- **Keeping the PR reviewer on Claude** (`claude-code-action`) — dropped in
  favour of a different provider on the diff: a Claude-reviews-Claude loop
  shares blind spots with the planner and implementer, and the PR stage is
  the cheapest place to get a genuinely independent model's eyes. The
  advisory-not-required reasoning below applies to any LLM reviewer, Claude
  or not.
- **A non-Anthropic _plan_ reviewer** (e.g. Kimi via `cmux`) — considered:
  Kimi exposes an Anthropic-compatible endpoint, so a second
  Claude-Code-on-Kimi is a clean reviewer. Rejected as the default because
  it's out-of-session (a separate pane, not the nested subagent the plan
  gate is built on) and adds day-to-day overhead; diversity lands at the
  PR/code stage instead, where CI already decouples it. Kept as a
  documented experiment to revisit.
- **A required LLM review check** — rejected: it must succeed to merge, so
  an outage or over-eager critique blocks all merges. Anthropic's own
  managed reviewer is deliberately non-blocking; gate on human approval.
- **The managed Code Review product** — rejected: Team/Enterprise-only, and
  it's Claude anyway, so no cross-model diversity.
- **An in-session router (claude-code-router / LiteLLM) to mix providers**
  — rejected: it routes by task type, not by "this is the reviewer," so it
  can't cleanly assign a provider per subagent, and it puts a third-party
  proxy in the request path. Out-of-session panes or a CI Action are
  cleaner for a reviewer split.
- **Automating any of the plan gate in CI** — rejected at both weights. A
  full `issues` workflow running the critique headlessly: per-ticket spend,
  no main-session context, unwanted autonomy. And even a trivial no-LLM
  workflow that stamps `needs-plan-review` on open: it can't classify type
  at open — an externally-filed issue arrives without a type label, so it
  over- or under-applies — and it duplicates the triage the grooming
  session already does. Folding the label into triage needs no CI and
  handles every issue source uniformly.
- **Orchestrating the plan loop from a main-session `/plan-issue` skill** —
  viable, and it keeps sequencing out of the PM worker, but the maintainer
  grooms in a dedicated `claude --agent backlog-manager` session, so the
  loop lives there and the backlog-manager drives it directly. The skill
  path stays available for grooming from a normal session.

## Consequences

- Re-scopes the epic's children: **#304** = PR-stage non-Anthropic advisory
  code reviewer (a model-configurable review Action, advisory, not
  required) + its provider key; **#305** = issue-stage plan gate (the
  backlog-manager orchestration below + `needs-plan-review` /
  `plan-approved` labels, a simpler two-state than the earlier
  plan-ready/plan-drafted/plan-reviewed triad, **no CI**).
- **#305 is entirely a backlog-manager change:** it gains a scoped
  `Agent(plan-reviewer)` tool, instructions to find untriaged issues (open
  with no `priority:` label), triage → apply `needs-plan-review` for feat+
  → draft → review → converge, and the label protocol. Its charter broadens
  to issue-level implementation planning. Grooming is a dedicated
  `claude --agent backlog-manager` session, so the backlog-manager is the
  main thread and can spawn the reviewer directly — no main-session
  `/plan-issue` skill needed (that alternative stays available for the
  non-dedicated path).
- **Model tiers are pinned in config:** `plan-reviewer` → `claude-opus-4-8`
  and `backlog-manager` → `claude-sonnet-5`, both in frontmatter; the
  implementer runs on `claude-haiku-4-5-20251001` at session launch.
  Cheapest execution under governance, premium adversarial review, a
  cheaper draft.
- Any issue source is handled uniformly: a human via the web, another
  repo's agent, or the maintainer all land in the backlog, and the grooming
  session's triage is the single point where the gate is applied. The plan
  gate is this repo's local convention (its labels + the backlog-manager's
  instructions), not something imposed on how other repos run — a foreign
  agent just files the issue; this repo gates it.
- #300's `plan-reviewer` subagent definition is otherwise unchanged — only
  its model pin and its issue-stage trigger are fixed here. Local pre-push
  code review stays the existing `/code-review` skill.
- One manual step gates the PR reviewer: provision the provider key (e.g.
  `OPENAI_API_KEY`) as a repo secret. Until then the review Action is inert,
  not broken; the plan gate needs no secret and no CI.
- Merge-gating risk stays zero — the reviewer is advisory, and the gate that
  exists is human approval.
- Revisit if: the chosen review Action's model or pricing changes,
  cross-model diversity proves not worth the extra key, or a Kimi-via-cmux
  plan reviewer is worth trialling.
