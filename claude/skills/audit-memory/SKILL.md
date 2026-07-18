---
name: audit-memory
description: >-
  Read-only audit of a repo's subagent project-memory (`.claude/agent-memory/<name>/`) for
  staleness against live GitHub state, one-home duplication of issue content, a drifted MEMORY.md
  index, sprawl, and durable content that belongs in README/AGENTS.md/docs instead — reporting
  proposed fixes without editing anything. Use when asked to audit, review, or check
  agent/backlog-manager memory for stale pointers, restated issue status, orphaned or dangling
  memory files, files that have grown too long, or memory content that should live in repo docs
  instead. The detection backstop to the write-time discipline in `backlog-manager.md`. Read-only
  — never invoke it to apply a fix.
allowed-tools: Read, Glob, Grep, Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh search issues:*), Bash(gh label list:*)
disallowed-tools: Write, Edit
---

# Audit Memory

Read-only audit of a subagent's committed project memory — the detection half of keeping that
memory honest, paired with the write-time "read `origin/main` before writing" discipline in
`backlog-manager.md` (prevention). Sibling to `audit-rules`: same propose-don't-apply contract,
same report shape, a different target. Report findings and proposed fixes — never edit anything.

**The auditor is not the author.** This runs as its own skill precisely so the actor that writes
memory doesn't grade its own work — a deliberate independent read, the same reason `audit-rules`
exists as a separate pass. Don't invoke it _as_ the backlog-manager.

**On the read-only guarantee.** `disallowed-tools` blocks Write/Edit, and Bash is scoped in
`allowed-tools` to read-only `gh` queries (`view`/`list`/`search`, `label list`). That's a
narrower guarantee than `audit-rules`' no-Bash-at-all — `gh` is also a _write_ interface — so the
rule is explicit: only ever run those read subcommands. Never `gh issue close/edit/comment`, never
`gh api` with a mutating method, never shell redirection or `sed -i`. If a check needs a write,
it's out of scope — report it, don't do it.

## Scope

Audit the current repo's `.claude/agent-memory/*/` — each subagent's own memory directory, its
`MEMORY.md` index plus the topic `*.md` files beside it. Read those files directly.

Bound the glob carefully — the tree has decoys that will corrupt the checks if swept in:

- Match `.claude/agent-memory/*/*.md` only (each subagent dir, one level of files). **Not**
  recursive.
- Exclude `.claude/worktrees/**` — linked worktrees carry their own mirrored copies of the memory.
- Exclude any self-nested `.claude/agent-memory/**/.claude/agent-memory/**` copy — accidental cruft
  from a run whose working directory sat inside the memory dir. If you find one, note it as a stray
  artifact to delete, but don't audit its contents as if they were real.

If the repo has no `.claude/agent-memory/` (the skill deploys globally; the memory only exists
where a subagent has actually run), say so and stop — "no agent memory in this repo," not a pile
of empty findings.

Also read this repo's `README.md`, `AGENTS.md` (or the `CLAUDE.md` it's symlinked from), and
top-level `docs/*.md` when they exist — comparison targets for the Misplaced durable content check
below, not optional context. Not recursive into `docs/` subdirectories (an `adr/` archive of
point-in-time decisions is expected to reference or echo doc content by nature, not drift by
accident) — same scope `audit-rules`' Cross-doc replication check uses; don't re-derive it here.

## Staleness vs live GitHub state

Memory is meant to hold decisions and _point at_ issues for status — `MEMORY.md` says so:
"live status lives on the issue." So the target is not a bare reference to a now-closed issue
(referencing a shipped record is correct); it's an **assertion of fact the memory embeds that
current state contradicts**.

- Flag embedded status claims — `#302 (OPEN)`, `#273 (OPEN, priority low)`, "not created yet",
  "still blocking", "superseded by" — and cross-check each against live state with a read-only `gh`
  query (`gh issue view <n>`). Report any that have moved: memory says open, `gh` says closed;
  memory says "not created yet" for a label that now exists.
- Prefer the DRY remedy over an in-place correction: an embedded live status duplicates what the
  issue already owns, so the fix is usually **drop the restated status and point at `#N`**, not
  "update the number." That folds this finding into the one-home check below — say so when it
  applies. Correcting-in-place is only right for a genuinely durable claim that isn't the issue's to
  own.

Stay conservative, the same "quiet on noise" bar as `audit-rules`: a bare `#N` cross-reference,
or naming an issue as a parent/child, is not a staleness finding.

## One-home duplication

The single-source-of-truth check, pointed at memory: a memory file restating an issue's body (its
description, acceptance criteria, current status) instead of holding the _decision and why_ and
pointing at the issue. Also flag the same fact restated across two memory files — it should live in
one and be pointed at from the other, exactly as `audit-rules`' Cross-doc replication treats
AGENTS.md/README.

Substantial means the same claim with the same specifics, not a shared issue number or tool name.
For each, quote both places and propose which one keeps it and which points instead.

## Broken index

`MEMORY.md` is the loaded-every-session index; the topic files are its targets. Flag the two ways
they drift apart:

- **Dangling pointer** — `MEMORY.md` links a file (`[label](topic.md)`) that doesn't exist.
- **Orphan** — a topic `*.md` in the directory that nothing in `MEMORY.md` links to (so it's never
  discovered). Exclude `MEMORY.md` itself from this check — it's the index, not an indexed file.

## Sprawl and contradiction

Same shapes as `audit-rules`, calibrated for memory:

- **Length / topic span** — these are heredoc-authored working notes, not published prose (they're
  exempt from the markdownlint/prettier hooks for that reason), so don't hold them to a published-doc
  line count. `MEMORY.md` should stay a lean index; a topic file that has outgrown its single
  subject or drifted into covering several unrelated facts is the target — judged by topic span
  first, with length only the symptom. Propose the split or the prune.
- **Contradiction** — two memory files (or two sections) asserting opposite facts, the way
  `audit-rules` checks the rules tree. Quote both, say which looks current.

## Misplaced durable content

The doc↔memory sibling of `audit-rules`' Cross-doc replication check: content sitting in memory
that's actually general repo documentation, not backlog-manager-audience material, and isn't
already stated in README.md/AGENTS.md/docs.

**Scope**: `project`- and `reference`-type entries only — check each file's `metadata: type:`
frontmatter. Skip `user`- and `feedback`-type entries outright; they're about how to work with the
maintainer, not repo-documentation material, by nature — never flag them here.

**What counts as misplaced**: a passage in scope whose content would inform any future contributor
or coding session, not just a triage/grooming session, and isn't already stated in
README.md/AGENTS.md/docs. Durability alone doesn't make something misplaced — audience does: a
decision's priority weighting, a labeling/grooming convention, or a cross-repo dependency web is
backlog-manager-audience by nature and stays put even though it's durable. An architecture
rationale, an XDG exception, or a convention any coding session would need is the target.

For each finding: quote the memory passage, name which doc should own it — reuse this repo's own
doc-home split if one exists (README = front door, AGENTS.md = how to work here, an ADR = a major
decision with rejected alternatives considered), exactly as `audit-rules`' Cross-doc replication
check already does; don't re-derive the split inline — and propose shrinking the memory passage to
a pointer once promoted, matching the signpost pattern used everywhere else in this repo's docs.

Stay conservative, the same "quiet on noise" bar as every other check here: don't flag a claim just
because it's durable — it has to be general-audience _and_ absent from README/AGENTS.md/docs.

## Report

Emit one structured markdown report directly in this response:

```markdown
# Memory Audit

No edits made — this is a proposal only.

## Staleness

(ranked most-confident first, or "None found.")

## One-home duplication

(ranked, or "None found.")

## Broken index

(ranked, or "None found.")

## Sprawl & contradiction

(ranked, or "None found.")

## Misplaced durable content

(ranked, or "None found.")

No edits made — this is a proposal only.
```

Each item is self-contained: what's wrong, where (file + quote), and a proposed direction — a
suggestion, not a diff, since this skill cannot write. Applying any fix, and committing the result
through the normal `chore(claude): sync <agent> memory` flow, stays a human call.
