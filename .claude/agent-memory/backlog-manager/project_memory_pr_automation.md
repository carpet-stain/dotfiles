---
name: project-memory-pr-automation
description: Memory-system redesign — epic #419 is the single entry point; three non-recoverable lessons
metadata:
  type: project
---

**The memory-system redesign (2026-07-24/25) lives in epic #419** — target design, children,
sequencing, and live state are all there, not here. The governing ADRs as they land: ADR-0032
(rolling sync PR), ADR-0033 (content contract).

**Lesson 1 (load-bearing for any audit-automation design): `Agent(subagent_type: ...)` gives a
real isolated context; invoking a *skill* does not.** A skill runs in the caller's own context —
"delegating" to the audit-memory skill is still self-grading. The first #411 plan was built on
the wrong assumption; plan-reviewer caught it, not me.

**Lesson 2: never hand-extend or hand-reconcile an in-flight memory-sync PR another session
touched.** Doing so cost an unrelated uncommitted `git/config` edit to a `git reset --hard`
(unrecoverable — never staged; the pre-reset `git status` warning was visible and not acted on).
ADR-0032's fixed-branch design removes the temptation.

**Lesson 3 (validated twice in one session): the read-fresh-before-write discipline is what
catches parallel-session drift** — only a fresh `git fetch` + `git show origin/main:<path>` read
prevented a stale overwrite when `origin/main` moved mid-session.
