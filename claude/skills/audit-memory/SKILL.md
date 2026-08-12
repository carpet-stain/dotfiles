---
name: audit-memory
description: >-
  Read-only audit of backlog-manager's MCP knowledge-graph memory (the JSONL store at
  `~/.claude/agent-memory-mcp/backlog-manager.jsonl`) for staleness against live GitHub state,
  one-home duplication of issue content, broken graph structure (dangling relations, orphaned
  entities, malformed repo-map entities), sprawl, and durable content that belongs in a durable
  documentation home (README/AGENTS.md/ADR) instead — reporting proposed fixes without editing
  anything. Use when asked to audit, review, or check agent/backlog-manager memory for stale
  pointers, restated issue status, orphaned entities, entities that have outgrown one topic, or
  memory content that should live in repo docs instead. The detection backstop to the write-time
  contract in `backlog-manager.md`. Read-only — never invoke it to apply a fix.
allowed-tools: Read, Glob, Grep, Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh search issues:*), Bash(gh label list:*), Bash(jq:*)
disallowed-tools: Write, Edit
---

# Audit Memory

Read-only audit of backlog-manager's knowledge-graph memory — the detection half of keeping that
memory honest, paired with the write-time pointer-layer contract in `backlog-manager.md`
(prevention; ADR-0036 owns the model). Sibling to `audit-rules`: same propose-don't-apply
contract, same report shape, a different target. Report findings and proposed fixes — never edit
anything.

**The auditor is not the author.** This runs as its own skill precisely so the actor that writes
memory doesn't grade its own work — a deliberate independent read, the same reason `audit-rules`
exists as a separate pass. Don't invoke it _as_ the backlog-manager — and since a skill runs in
its caller's context, a session that wrote memory runs it via a **fresh-context subagent**
pointed at this file, never inline (the sanctioned pattern per #412's spike decision).

**On the read-only guarantee.** `disallowed-tools` blocks Write/Edit; the store is read as a
plain file (Read/jq), never through the `mcp__memory` write-capable tools; and Bash is scoped in
`allowed-tools` to read-only `gh` queries (`view`/`list`/`search`, `label list`) plus `jq`.
`gh` is also a _write_ interface, so the rule is explicit: only ever run those read subcommands.
Never `gh issue close/edit/comment`, never `gh api` with a mutating method, never shell
redirection into the store or `sed -i`. If a check needs a write, it's out of scope — report it,
don't do it.

## Scope

Audit the machine-global store `~/.claude/agent-memory-mcp/backlog-manager.jsonl` — one JSONL
file, one record per line: `{"type":"entity","name":...,"entityType":...,"observations":[...]}`
or `{"type":"relation","from":...,"to":...,"relationType":...}`. Read it directly (Read or jq);
it is deliberately human-readable (ADR-0036). If the file is missing or empty, say so and stop —
"no graph memory on this machine," not a pile of empty findings.

The graph spans every repo. Repo scoping is relational: `repo-map` entities name the repos;
`informs` relations tie repo-scoped facts to them. Doc-comparison checks (Misplaced durable
content) judge a fact against the docs of the repo it informs — run them for repos with a
checkout you can read (probe the `repo-map` entity's checkout hint; it's marked non-portable, a
wrong value means _unknown_); list any repo you skipped for lack of a checkout rather than
silently narrowing.

For each repo audited, read its `README.md`, `AGENTS.md` (or the `CLAUDE.md` it's symlinked
from), and top-level `docs/*.md` when they exist — comparison targets for the Misplaced durable
content check, not optional context. Not recursive into `docs/` subdirectories (an `adr/`
archive of point-in-time decisions is expected to reference or echo doc content by nature, not
drift by accident) — same scope `audit-rules`' Cross-doc replication check uses; don't re-derive
it here.

## Staleness vs live GitHub state

Memory is meant to hold decisions and _point at_ issues for status — the contract says so: live
status lives on the issue. So the target is not a bare reference to a now-closed issue
(referencing a shipped record is correct); it's an **assertion of fact an observation embeds
that current state contradicts**.

- Flag embedded status claims — `#302 (OPEN)`, "not created yet", "still blocking", "pending
  write" — and cross-check each against live state with a read-only `gh` query
  (`gh issue view <n> -R <owner>/<repo>`; resolve a bare `#N` through the entity's `informs`
  relation). Report any that have moved: memory says open, `gh` says closed; memory says "not
  created yet" for a label that now exists.
- Prefer the DRY remedy over an in-place correction: an embedded live status duplicates what the
  issue already owns, so the fix is usually **drop the restated status and point at `#N`**, not
  "update the number." That folds this finding into the one-home check below — say so when it
  applies. Correcting-in-place is only right for a genuinely durable claim that isn't the
  issue's to own.

Stay conservative, the same "quiet on noise" bar as `audit-rules`: a bare `#N` cross-reference,
or naming an issue as a parent/child, is not a staleness finding.

## One-home duplication

The single-source-of-truth check, pointed at memory: an observation restating an issue's body
(its description, acceptance criteria, current status) instead of holding the _decision and why_
and pointing at the issue. Also flag the same fact restated across two entities — it should live
on one and be reachable from the other (a `relates-to` relation, or a pointer observation),
exactly as `audit-rules`' Cross-doc replication treats AGENTS.md/README.

Substantial means the same claim with the same specifics, not a shared issue number or tool
name. For each, quote both places and propose which entity keeps it and which points instead.

## Broken graph

The structural checks — shape, not meaning:

- **Dangling relation** — a relation whose `from` or `to` names no entity in the store.
- **Orphan fact** — a `project`- or `reference`-type entity with no `informs` relation to any
  `repo-map` entity (so repo-scoped recall never reaches it). `user`/`feedback` entities are
  legitimately global — never orphans.
- **Duplicate entity names** — two entity lines with the same `name` (the server treats names as
  identity; a duplicate means a write bypassed it or a merge went wrong).
- **Malformed repo-map** — a `repo-map` entity's observations must be exactly: a one-line hook;
  optionally a checkout-path hint marked non-portable; optionally pending-relocation pointer(s),
  each exactly `<repo>#<N>` plus at most a one-line hook. Prose beyond that schema is a finding,
  judged per-observation. No semantic judgment — the `entityType` is the mode selector, same as
  the old filename split.
- **Malformed record** — a line that isn't valid JSON, or an entity whose `entityType` isn't one
  of `project`/`reference`/`user`/`feedback`/`repo-map`.

## Sprawl and contradiction

Same shapes as `audit-rules`, calibrated for a graph:

- **Topic span** — one entity whose observations have drifted across several unrelated subjects;
  the entity name should describe all of them and can't. Judged by topic span first, with
  observation count only the symptom. Propose the split (new entity + relation) or the prune.
- **Contradiction** — two observations (same entity or different ones) asserting opposite facts,
  the way `audit-rules` checks the rules tree. Quote both, say which looks current.

## Misplaced durable content

The doc↔memory sibling of `audit-rules`' Cross-doc replication check: content sitting in memory
that belongs in a durable documentation home — README, AGENTS.md, or an ADR — rather than in
memory, because it's general repo documentation, not backlog-manager-audience material, and
isn't already stated in README.md/AGENTS.md/docs. The spec for what memory may hold at all is
the pointer-layer contract (ADR-0033, carried into ADR-0036); this check is its lint.

Two boundaries, fixed deliberately:

- The Scope section's `adr/` read-exclusion stands even though an ADR is a named promotion
  target: ADR is a _proposal target_, never a read-surface for de-dup suppression. Promotion
  leaves only a pointer in memory, so there's nothing left to false-positive on.
- **"The issue" is not a promotion target for this check.** Memory↔issue traffic is already
  owned by the Staleness and One-home checks above; this check stays the doc↔memory sibling.

**Scope**: `project`- and `reference`-type entities only. Skip `user`- and `feedback`-type
entities outright; they're about how to work with the maintainer, not repo-documentation
material, by nature — never flag them here. `repo-map` entities are owned by the structural
check above.

**What counts as misplaced**: an observation in scope whose content would inform any future
contributor or coding session, not just a triage/grooming session, and isn't already stated in
that repo's README.md/AGENTS.md/docs. Durability alone doesn't make something misplaced —
audience does: a decision's priority weighting, a labeling/grooming convention, or a cross-repo
dependency web is backlog-manager-audience by nature and stays put even though it's durable. An
architecture rationale, an XDG exception, or a convention any coding session would need is the
target.

For each finding: quote the observation, name which doc should own it — reuse that repo's own
doc-home split if one exists (README = front door, AGENTS.md = how to work here, an ADR = a
major decision with rejected alternatives considered), exactly as `audit-rules`' Cross-doc
replication check already does; don't re-derive the split inline — and propose shrinking the
observation to a pointer once promoted, matching the signpost pattern used everywhere else.

Stay conservative, the same "quiet on noise" bar as every other check here: don't flag a claim
just because it's durable — it has to be general-audience _and_ absent from
README/AGENTS.md/docs.

## Report

Emit one structured markdown report directly in this response:

```markdown
# Memory Audit

No edits made — this is a proposal only.

## Staleness

(ranked most-confident first, or "None found.")

## One-home duplication

(ranked, or "None found.")

## Broken graph

(ranked, or "None found.")

## Sprawl & contradiction

(ranked, or "None found.")

## Misplaced durable content

(ranked, or "None found.")

No edits made — this is a proposal only.
```

Each item is self-contained: what's wrong, where (entity name + quoted observation), and a
proposed direction — a suggestion, not a diff, since this skill cannot write. Applying any fix
happens through the agent's own `mcp__memory` tools in a later session, and stays a human call.
