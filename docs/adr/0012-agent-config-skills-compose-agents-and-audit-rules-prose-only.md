# 12. Agent-config skills: compose-agents and audit-rules, prose-only

Date: 2026-07-11

## Status

Accepted

## Context

The 0008 rules tree is abstract: each file carries a COMPOSE block plus
GATE/LOCAL-WINS metadata, meant to be instantiated per repo (#97). Two recurring
jobs had no tool: turning those abstracts into a concrete repo `AGENTS.md`, and
keeping the tree itself healthy. Instantiation was manual and error-prone —
`github.md` has no COMPOSE block of its own and folds into `git.md`'s sections,
and detected facts (scopes, branch model, pre-commit tool) need extraction
(#111). On the maintenance side the removal test says automate only after manual
review demonstrably fails; it did once — the "negligible token cost"
contradiction slipped in and survived until a hand read caught it, fixed in #106
(#112). Both jobs are one-shot analyses in the main context, no persistent
memory or delegation, so a skill fits, not a subagent (#112). Epic #97 scoped
both as skills on top of 0008.

## Decision

Ship two agent-config skills on top of the 0008 rules tree. compose-agents
(#111, PR #114) instantiates each applicable rule file's COMPOSE block into a
repo's `AGENTS.md`, filling `<placeholders>` with repo facts extracted by a
bundled `scripts/detect.sh`, and matching this repo's own `AGENTS.md` as the
literal template (SKILL.md line 72). audit-rules (#112, PR #113) reads the rules
tree read-only and reports contradictions and topic/length sprawl (later also
cross-doc replication, #178), proposing fixes. Both are prose-driven SKILL.md
skills, stateless, in the main context. Both are propose-only: audit-rules never
writes (`disallowed-tools` blocks Write/Edit structurally); compose-agents keeps
Write/Edit out of its `allowed-tools` and waits for an explicit approval turn
before writing. audit-rules landed first (273b49d8) carrying the shared
`claude/skills/` deploy plumbing both use.

## Alternatives considered

- **Skills that auto-edit / auto-write the repo's files** — both skills present
  a draft/diff and wait; audit-rules hard-blocks Write/Edit via
  `disallowed-tools`, turning propose-don't-apply into a structural guarantee
  instead of a prose promise (#112). compose-agents keeps Write/Edit off its
  `allowed-tools` until an explicit approval turn and forbids shelling out via
  Bash (`cat > AGENTS.md`) to route around it — a mature repo's doc is never
  silently overwritten or re-distilled back into the abstracts, the design's
  cardinal rule (compose-agents SKILL.md lines 21-26, 34; #111).
- **Layer onto /init instead of a separate skill** — `/init` is a built-in
  Claude Code skill, not a file in this repo to extend. compose-agents adds
  awareness of the global rules and their COMPOSE blocks, and deliberately
  scopes its repo-domain drafting down from `/init`'s full codebase analysis to
  skeleton headers + TODO markers, pointing at `/init` for deeper drafting
  (#111; SKILL.md Step 5).
- **A subagent for the rules audit** — a subagent earns its place only when
  persistent memory, repeated delegation, and context isolation all apply (as
  with backlog-manager). Auditing is a one-shot analysis — none hold. Skill
  (#112).
- **Prose-only detection for compose-agents (re-grep facts each run)** — the
  facts (scopes, branch model, version scheme, pre-commit tool, credentials) are
  deterministic and better extracted reproducibly than re-derived fresh each
  run, so compose-agents bundles a read-only `detect.sh` (#111); audit-rules
  stays script-free because its checks are judgment calls and
  line-count-over-200 comes free from the Read tool's numbering, so no Bash/wc
  hole in the allowlist is warranted (#112).
- **Auto-detect exemplar/anti-pattern files and translate permission prose into
  settings.json (in v1 compose-agents)** — exemplar auto-detection is semantic
  judgment, false-positive prone; the prose→settings.json translation is
  genuinely underspecified — real scope creep. Both deferred to follow-ups; the
  cheap TODO-prompt version of exemplars stays in v1 (#111; SKILL.md Step 5,
  "Not in scope for v1").
- **A memory-backed longitudinal rule-tracker (remove-a-rule-once-followed)** —
  the removal test justifies the audit skill from one proven miss (#106) but not
  a longitudinal tracker — no evidence manual review can't handle the two
  judgment gates yet; they stay human calls (#112).

## Consequences

Instantiating a repo's `AGENTS.md` and health-checking the rules tree are now
repeatable skill runs, not ad-hoc reads. compose-agents was live-tested in
suggest-diff mode against this repo (`AGENTS.md` already exists): near-empty
diff, confirming it handles the two real traps — `github.md` folding into
`git.md`'s sections, and a detected branch-model divergence being flagged rather
than fabricated (7fbcc03d). audit-rules dogfoods clean on the current tree now
that the earlier contradiction is fixed (#106) and would have flagged it before
(#112). Enforcement: audit-rules' `disallowed-tools`; compose-agents' soft prose
gate plus absent Write/Edit in its `allowed-tools`. Both depend on 0008 — if the
rules-tree shape changes (COMPOSE blocks, GATE/LOCAL-WINS, the ~200-line
threshold, the lineage/override markers), both skills must track it; a249c161
already reconciled compose-agents after #128 collapsed git.md to one branch
model. The deferred pieces (exemplar auto-detection, prose→settings.json) are
revisit triggers if manual handling proves insufficient. The two maintenance
judgment gates stay human — revisit a memory-backed helper only if manual audits
prove insufficient (#112).
