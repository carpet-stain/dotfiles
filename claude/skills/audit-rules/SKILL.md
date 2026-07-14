---
name: audit-rules
description: >-
  Audits the global Claude Code agent-config rules tree (~/.claude/rules) for
  contradictions and topic/length sprawl, and checks AGENTS.md/README.md/docs for content
  substantially duplicated across them, reporting proposed fixes without editing anything.
  Use when asked to audit, review, or check claude/rules for contradictions, conflicting
  directives, files that have grown too long or cover more than one topic, or repo docs
  that restate the same content in more than one place. Read-only — never invoke this to
  apply a fix, only to find issues.
argument-hint: "[path]"
allowed-tools: Read, Glob, Grep
disallowed-tools: Write, Edit
---

# Audit Rules

Read-only audit of the global agent-config rules tree for the two maintenance issues the
removal test cares about: contradictions and sprawl. Also checks this repo's own docs
(AGENTS.md/README.md/docs) for content replicated across them — a doc↔doc instance of the same
single-source-of-truth problem, and a named cause of sprawl. Report findings and proposed
fixes — never edit anything yourself. `disallowed-tools` already blocks Write/Edit
structurally; treat that as a guarantee, not just a reminder.

## Scope

Read target: `~/.claude/rules/**/*.md`. Never hardcode a specific repo's path (e.g. a
dotfiles checkout) — this must work from any repo where the rules are deployed.

If invoked with a path argument, scope the audit to that file or directory instead of the whole
tree (useful mid-edit on a single file). Otherwise audit everything.

Also read the current repo's own `AGENTS.md`, `README.md`, and any top-level `docs/*.md`
(not nested subdirectories — see Cross-doc replication check's scope note), if present — needed
for the local-doc contradiction check below, the AGENTS.md length check under Sprawl, and the
Cross-doc replication check.

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

### Sprawl reduction playbook (AGENTS.md over threshold)

"Too long" alone re-derives the same menu every run. Once a cause above applies, propose cuts
in this order — each is a strategy that actually shrank a doc in this repo's own history,
highest-confidence first:

1. **Signpost + link.** A section re-explaining content another doc owns collapses to a 1-3
   line essence plus a pointer (`see README.md § ...`, or this repo's doc-home-map if one
   exists). Verify the target doc actually covers it before cutting toward it — pointing at a
   doc that doesn't hold the material loses the content, it doesn't relocate it. De-duping
   AGENTS.md against README this way (philosophy list, XDG principle, structure blurb, each
   folded to a pointer) took one repo's copy 318 → 305 lines in a single pass.
2. **Drop restated-enforcement.** Prose spelling out an exact value a config already enforces
   (a CI regex's allowed-type list, a linter's rule codes) is the Restated-enforcement check's
   target — cut it there, not just here. The same instinct, applied across this repo's whole
   rules tree, was the largest single trim on record: 574 → 360 lines (-37%), no directive lost.
3. **Cut restated-principle sections.** A repo-local section that just re-lists an
   always-loaded `rules/universal/*` principle is pure duplication — the universal rule applies
   every session regardless of whether AGENTS.md repeats it. Keep only the repo-specific slice
   (e.g. which doc owns which fact); drop the generic restatement.
4. **Collapse intra-file overlap.** Two sections echoing the same point (a checklist repeated
   in two places, a rule stated once under "editing" and again under "git workflow") merge into
   one, cross-referenced from where the other used to be.
5. **Titles over prose.** For an enumerated list, keep the scannable numbered heading plus one
   pointer to the doc that owns the reasoning; cut the per-item explanatory paragraph. Merging
   redundant "why" sections this way took this repo's own `claude/README.md` from 326 → 265
   lines with no content lost.
6. **Merge duplicate command blocks.** Near-identical fenced command examples collapse to one.
7. **Fix source-of-truth direction.** If AGENTS.md holds mechanics another doc should own, move
   the mechanics there and have AGENTS.md point — don't just trim in place. Watch for the
   circular-pointer trap: the two docs must not each say "see the other."

**The honest floor.** After exhausting 1-7, the remainder is legitimate unique agent content
(layer map, source-of-truth map, failure-stage semantics) already at essence-plus-pointer —
don't force it thinner by externalizing high-value content behind an extra hop just to clear
the firm-flag. Report "restatement and overlap eliminated; residual N lines are unique
content," not "still over threshold, keep cutting."

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

## Cross-doc replication check

Issue #140's restated-enforcement check is doc↔config: prose restating a spec a config already
enforces. This check is the doc↔doc sibling — same single-source-of-truth violation, different
pair: substantial content restated across AGENTS.md, README.md, and top-level `docs/*.md`
instead of living in exactly one and being pointed at from the others. Unpruned replication
between these is a named top cause of AGENTS.md's length problem (#178) — this check names
which content to cut, length only measures the symptom.

**Substantial** means a full sentence, list item, or table row making the same claim with the
same specifics (not just both docs mentioning "XDG" or "Homebrew") — near-verbatim wording isn't
required, same claim/same specifics is what makes it substantial. A shared proper noun, tool
name, or one-line cross-reference is not substantial; don't flag those. If in doubt whether a
match clears the bar, don't report it — this check should stay quiet on noise, not cry wolf on
every shared word.

For each substantial match:

- Quote both locations (file + the specific passage) side by side.
- Propose which doc should own it and which should point instead of restate. Use this repo's own
  ownership split if a "one home per fact" doc-home-map exists (check for it — AGENTS.md may
  define one); absent that, default to the shape both README.md and AGENTS.md already state for
  themselves in this repo: README is the front door (what this is, why, install, use), AGENTS.md
  is how to work here. Don't invent or restate that split yourself if the repo already states it
  somewhere — point at wherever it's defined instead of re-deriving it inline in the report.
- Suggest the pointer-form replacement in the doc that should stop restating (a one-line
  cross-reference), not a full rewrite — same "propose, don't diff" limit as the other checks.

Scope stays to the docs an agent relies on for context — AGENTS.md, README.md, top-level
`docs/*.md` — not general repo-doc linting. Don't descend into `docs/` subdirectories (e.g. an
`adr/` archive of point-in-time decisions is expected to reference or echo AGENTS.md/README
content by nature, not drift by accident) and don't extend this check to CHANGELOG.md,
per-tool READMEs, or code comments.

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

## Cross-doc replication

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
