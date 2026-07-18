# 26. skills activate on description-match, no activation-nudge hook

Date: 2026-07-18

## Status

Proposed

## Context

Skills are on-demand: Claude Code invokes one by name (`/skill-name`) or
auto-invokes it when its `description` matches the request. Auto-invocation
on description alone isn't perfectly reliable, so the diet103 showcase
makes skills fire with a `skill-rules.json` trigger map (keywords, intent
regex, file-path and content patterns) plus a `UserPromptSubmit` hook that
injects a "consider skill X" reminder, and a `PreToolUse` guard that can
block edits until a mandatory skill activates.

Spike #301 asks whether a _minimal_ slice of that — a small trigger map
feeding a one-line, non-blocking `UserPromptSubmit` nudge — earns its
complexity here. #298 already rejected the heavy parts (the blocking
guard, LLM classification, the vector store), so this decides only the
lightest version. The setup it would serve: two machine-global skills
(`audit-rules`, `compose-agents`) with descriptions already written for
auto-invocation, deployed by symlink into `~/.claude/skills`.

## Decision

Rely on description-match plus explicit `/skill` invocation. Add no
activation hook, not even the minimal nudge.

A trigger map is a second home for the same fact the skill's `description`
already owns — "when does this skill apply." Two homes drift: tune a
skill's triggers and the description falls behind, or the reverse. That's
the one-home/single-source rule this repo keeps everywhere else (ADR-0018,
and `audit-rules`' own doc↔doc check), applied to skill activation. The
right fix for an under-firing skill is a sharper `description`, edited in
one place, not a parallel rules file shadowing it.

The gain doesn't cover that cost at this scale: two skills, both with crisp
descriptions, and `/skill` always available as the explicit fallback when
auto-match misses. The showcase itself ships skill-activation `disabled`
by default — its own authors don't trust the rig on. A `UserPromptSubmit`
hook is also always-on machinery — it runs on every prompt, in every repo,
since the skills are global — to raise the hit rate of two already-
discoverable skills, the kind of infra #298 was written to keep out.

## Alternatives considered

- **Minimal `UserPromptSubmit` nudge hook** — a small trigger map → a
  one-line non-blocking reminder. Rejected: the trigger map duplicates each
  skill's `description` (drift, one-home violation), and it's always-on
  global machinery for a marginal reliability gain across two skills that
  `/skill` already covers. Revisit if the skill count grows enough that
  description-match demonstrably misses — reopen with the observed misses
  as evidence, not in the abstract.
- **The full showcase rig** (trigger map + nudge + `PreToolUse` blocking
  guard + LLM/vector classification) — already rejected in #298 as heavy
  infra for a solo machine-global setup; out of scope here except as the
  thing the minimal version is a slice of.
- **Do nothing and don't record it** — rejected: the showcase makes the
  hook look like an obvious win, so without a recorded "we weighed it and
  the trigger map fights one-home," it gets re-proposed every time the rig
  is seen again.

## Consequences

- Skill activation stays: description-match for auto-invocation, `/skill`
  for explicit. Keeping a skill discoverable is a `description`-quality
  job owned in one place — reinforced by the lean-`SKILL.md` convention
  (README Skills section) that already puts intent and triggers in the
  entry file.
- No hook to deploy, symlink, or keep in sync; nothing runs on
  `UserPromptSubmit`.
- Closes the "should skills have an activation forcing-function" question
  for now; #280 (the sibling "is skill machinery worth it" call for the
  nvim-verify tooling) is decided on its own merits.
- Revisit if the global skill set grows large, or auto-match is observed to
  miss often enough that a sharper description can't fix it — reopen from
  this ADR rather than re-deriving the trade.
