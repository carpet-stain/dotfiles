---
name: project-memory-pr-automation
description: Memory-system redesign — epic #419 is the single entry point (children #414/#416/#421/#390/#412/#411); three non-recoverable lessons
metadata:
  type: project
---

**The memory-system redesign went through a full first-principles pass (2026-07-24/25). Epic
#419 is the single entry point — target design, children, and sequencing all live there; read
live state from it, not this file:**

- **#414 (plan-approved)** — `git memory-pr` sync mechanism: fixed branch + one rolling draft PR
  as the write/merge-cadence buffer. Body carries the complete converged algorithm (7 review
  rounds). Fail-loud recovery was the operator's explicit call.
- **#416 (plan-approved)** — memory content contract: pointer layer keyed to the four existing
  frontmatter types, new ADR referencing ADR-0009, audit-memory's fifth check generalized as the
  lint, one atomic dev PR incl. the slim pass. Body is self-sufficient (4 rounds).
- **#421 (plan-approved)** — cross-repo memory residency: facts live in the repo whose backlog
  they inform; bounded `map_<repo>.md` schema; per-repo sync from each checkout.
- **#412 (spike, open)** — where auditor-independence is enforced; CI-side evaluated first.
- **#411 (open, blocked)** — auto-merge/ADR-0027 amendment; blocked on #390 + #412 + #416 +
  evidence per its redefined trigger. #390 (gitleaks) carries the memory-path-inclusion
  constraint.

**Lesson 1 (load-bearing for any future audit-automation design): `Agent(subagent_type: ...)`
gives a real isolated context; invoking a *skill* does not.** A skill runs in the caller's own
context — backlog-manager "delegating" to the audit-memory skill is still self-grading. The
first #411 plan was built on this wrong assumption; plan-reviewer caught it, not me.

**Lesson 2: never hand-extend or hand-reconcile an in-flight memory-sync PR another session
touched.** Doing so cost an unrelated uncommitted `git/config` edit to a `git reset --hard`
(unrecoverable — never staged; the pre-reset `git status` warning was visible and not acted on).
Branch fresh off current `origin/main` for new content instead; out-of-order small memory PRs
are fine. (#414's fixed-branch design removes the temptation once implemented.)

**Lesson 3 (meta, validated twice this same session): the read-fresh-before-write discipline is
what catches parallel-session drift** — twice, `origin/main` had moved under this session
(another session merging #401, then re-emitting #413's content after #404 merged), and only the
fresh `git fetch` + `git show origin/main:<path>` read prevented a stale overwrite.
