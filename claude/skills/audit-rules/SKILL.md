---
name: audit-rules
description: >-
  Audits the global Claude Code agent-config rules tree ($CLAUDE_CONFIG_DIR/rules) for
  contradictions and topic/length sprawl, reporting proposed fixes without editing anything.
  Use when asked to audit, review, or check claude/rules for contradictions, conflicting
  directives, or files that have grown too long or cover more than one topic. Read-only —
  never invoke this to apply a fix, only to find issues.
argument-hint: "[path]"
allowed-tools: Read, Glob, Grep
disallowed-tools: Write, Edit
---

# Audit Rules

Read-only audit of the global agent-config rules tree for the two maintenance issues the
removal test cares about: contradictions and sprawl. Report findings and proposed fixes —
never edit anything yourself. `disallowed-tools` already blocks Write/Edit structurally; treat
that as a guarantee, not just a reminder.

## Scope

Read target: `$CLAUDE_CONFIG_DIR/rules/**/*.md`, falling back to `~/.claude/rules` if the env
var is unset. Never hardcode a specific repo's path (e.g. a dotfiles checkout) — this must work
from any repo where the rules are deployed.

If invoked with a path argument, scope the audit to that file or directory instead of the whole
tree (useful mid-edit on a single file). Otherwise audit everything.

Also read the current repo's own `AGENTS.md` and any `docs/*.md`, if present — needed for the
local-doc contradiction check below and the AGENTS.md length check under Sprawl.

## Contradiction check

Read every file in scope fully, then look for:

- **Within-file**: a file asserting X in one section and not-X in another. The #106 "negligible
  token cost" contradiction in this repo is the worked example of this shape.
- **Cross-file**: two rules files disagreeing — e.g. a `universal/` file and a `tools/` file
  recommending opposite defaults.
- **Local-doc drift**: the repo's own `AGENTS.md`/`docs/` disagreeing with a rules file. This is
  _expected and fine_ under LOCAL-WINS when the local doc clearly overrides the point on
  purpose — only flag it when it reads like accidental drift instead of a deliberate override
  (e.g. the local doc doesn't acknowledge it's overriding anything, it just quietly contradicts).

Report most-confident first. Each finding quotes both locations (file path + the specific
sentence) and states plainly why they conflict.

## Sprawl check

**Rules tree** (`rules/**`) gets two independent signals:

- **Length**: files over ~200 lines — the threshold `claude/README.md`'s own "Why the rule
  files are terse" section names. The Read tool's line-numbered output gives you the count for
  free; no need to shell out.
- **Topic span**: does the file cover more than one coherent topic? This is a qualitative
  judgment from reading the content, not a heading-count metric — the precedent is
  `philosophy.md` splitting into the four `universal/` files once it outgrew a single topic.

**AGENTS.md and `docs/*.md`** get a length-only check, against the separate, higher threshold
`claude/README.md`'s "Why the rule files are terse" section names for composed per-repo guides
(soft-warn / firm-flag). Don't flag topic span there — spanning many topics is AGENTS.md's job.
When a file crosses the threshold, don't just report "too long": check it against the
Restated-enforcement check below and for unpruned topic overlap between its own sections, and
point at whichever applies as the cause and the pointer-form/de-dup prune as the remedy.

## Restated-enforcement check

AGENTS.md (or a rules file) should point at a config that already enforces something, not
restate the config's exact detail as prose — the same signpost-vs-spec distinction
`compose-agents` now applies when instantiating (see its "Pointer-form for enforced specs"
step). Flag prose in scope that enumerates an exact, mechanically-checkable value — a literal
list of allowed values, a regex, a numeric threshold — that a config file present in the current
repo already defines byte-for-byte. The Conventional-Commit type list restated in prose when a
CI workflow's regex already enforces it (this repo's own `pr-guards.yml` is the worked example)
is the shape to look for; a lint-rule-code list restated when a linter config already lists them
is the same shape.

Don't flag workflow _shape_ (step ordering, when to squash, when to open a PR) even when a slow
or CI-only gate enforces it — that's guidance no config can teach ahead of time, not a duplicated
spec, and removing it would just push discovery to the most expensive point. Only the enumerable
detail itself is the target.

Each finding quotes the restating prose and the enforcing config, and proposes the pointer-form
rewrite — same format as the Contradictions check, this is not a new report shape.

## Report

Emit one structured markdown report directly in this response:

```markdown
# Rules Audit

No edits made — this is a proposal only.

## Contradictions

(ranked most-confident first, or "None found.")

## Sprawl

(ranked, or "None found.")

## Restated enforcement

(ranked, or "None found.")

No edits made — this is a proposal only.
```

Each item is self-contained: what's wrong, where (file + quote), and a proposed direction to
resolve it — a suggestion, not a diff, since this skill cannot write.

## Non-goals

The two maintenance judgment gates from `claude/README.md`'s "Maintenance discipline" —
_add a rule only after it would have prevented an actual mistake_, and _remove a rule once it's
followed without being told_ — stay human calls. Don't attempt to apply either; this skill only
surfaces contradictions and sprawl for a human to weigh.
