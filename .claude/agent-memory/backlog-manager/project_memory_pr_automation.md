---
name: project-memory-pr-automation
description: Decision chain (2026-07-24) — whether/how to auto-merge git memory-pr's draft PR; gated on dotfiles#390 (gitleaks) + dotfiles#412 (audit-memory agent-vs-skill spike) + dotfiles#411 (ADR-0027 amendment, narrowed after plan review)
metadata:
  type: project
---

**Status: not yet decided, deliberately — and the first design attempt was wrong.** User asked
for two things: (1) `git memory-pr` should run `/audit-memory` automatically before opening the
PR, as a separate subagent with write access, (2) auto-merge the PR once opened. Both collided
with explicit, reasoned decisions already on record.

**Auto-merge was already considered and rejected once**, in ADR-0027's "Alternatives considered":
removes the human read-checkpoint that's the *only* coverage for secret-leak risk, since
`audit-memory` has zero secret-scanning capability. Not a style choice — the stated reason.

**2026-07-24: user pointed out dotfiles#390 ("add gitleaks secret-scanning") is already open and
targets ADR-0027's named gap.** Agreed, bumped #390 to `priority: high`, filed **dotfiles#411**
(architecture-labeled) to do the actual amendment once gitleaks lands.

**2026-07-24, later same day: drafted a plan for #411 that turned out to have a real, blocking
flaw — caught by `plan-reviewer`, not by me.** The plan assumed backlog-manager could "delegate to
a fresh `audit-memory` subagent instance via the Agent tool," the same way it delegates to
`plan-reviewer`. **Wrong: `audit-memory` is a skill, not an agent.** A skill runs in the *caller's
own context* — "delegating" to it doesn't isolate anything; backlog-manager is still the actor
running the audit, in the same context that wrote the memory. No auditor/author separation
actually happens this way. This is the load-bearing distinction for anyone touching this again:
**`Agent(subagent_type: ...)` gets you a real isolated context; invoking a skill does not**, even
when the skill's own doc talks about independence (audit-memory's "don't invoke it as the
backlog-manager" line assumes some other invocation path achieves that separation — it doesn't
specify which, and "the Agent tool, like plan-reviewer" turned out to be a wrong guess).

**Split the work as a result:**
- **dotfiles#412** (spike): does converting `audit-memory` (and its sibling `audit-rules`, same
  skill contract) to a real agent buy genuine independence, and what breaks doing that (symmetry
  between the two skills, whatever `compose-agents` assumes about their shape). Unresolved.
- **dotfiles#411** (narrowed): now purely the auto-merge/ADR-0027-amendment decision, explicitly
  blocked on #390 *and* #412 *and* actual evidence of ADR-0027's own named revisit trigger (draft
  PRs "piling up unreviewed in practice") — not the mere possibility of it. #401 (a second, older,
  unreviewed memory-sync PR that sat open for most of a day before finally getting merged instead
  of cleaned up — see below) is early, not-yet-conclusive evidence this might be starting.
- **dotfiles#390**: gained a load-bearing constraint from the same review — every existing content
  hook in this repo (`markdownlint`, `md-format`) excludes `.claude/agent-memory/**` (ADR-0009:
  memory is heredoc notes, exempt from format hooks). Gitleaks copying that hook shape would
  exempt exactly the content auto-merge makes dangerous. Added explicitly to #390's body so it
  doesn't get discovered post-implementation.

**Second, unrelated but concrete lesson from the same session — even the mechanical "commit and
push memory" step isn't safe to freelance.** Extending an already-open PR (#404) by hand (instead
of running the actual `git memory-pr` script fresh) led to two real mistakes: (1) `git reset
--hard` onto a rewritten remote tip discarded an unrelated uncommitted change to `git/config`
(irrecoverable — it was never staged) because the pre-reset `git status` warning wasn't acted on;
(2) PR #401, a second stale memory-sync branch from earlier the same day, got merged by someone
else in parallel, landing content this session didn't have — discovered only by re-fetching
`origin/main` before writing further, per the "read origin/main fresh, don't trust your in-context
copy" discipline, which is exactly what caught it. **Lesson: when a memory-sync branch already has
its own open PR and gets picked up/finalized by another session, don't keep extending it by hand —
branch a fresh one off current `origin/main` for new content instead**, same as this file's own
follow-up commit did. Two (or more) small memory PRs merging out of order is fine and expected;
hand-reconciling someone else's in-flight branch is where the risk lives.

**Still not decided, still gated:** whether `audit-memory` becomes an agent (#412), whether
auto-merge ships at all (#411), and if it does, where the audit gate gets enforced (script/CI, not
agent prompt — a prose-only gate protects nothing once a machine-global script's default is
auto-merge). Check #411/#412's live state before assuming any of this has resolved.
