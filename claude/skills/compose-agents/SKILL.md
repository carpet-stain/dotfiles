---
name: compose-agents
description: >-
  Drafts or updates a repo's AGENTS.md by instantiating the global Claude Code rules tree
  (~/.claude/rules) with this repo's detected facts (branch model, version scheme,
  scopes, pre-commit tooling, credential pattern), following each rule file's COMPOSE block.
  Use when asked to scaffold AGENTS.md, set up agent config for this repo, compose or
  instantiate the rules into a repo doc, check whether an existing AGENTS.md has drifted from
  the abstract rules, or augment a doc that predates the rules with the instantiations it's
  missing. Never creates or edits AGENTS.md directly — always presents a full draft or diff in
  chat and waits for explicit approval before any file is written.
allowed-tools: Read, Glob, Grep, Bash
---

# Compose Agents

Instantiates the global agent-config rules tree into this repo's `AGENTS.md`. Operates on the
current working directory only — like `/init`, not a skill for scaffolding some other repo by
path.

**This skill never writes `AGENTS.md` itself.** `Write`/`Edit` aren't in its `allowed-tools` for
a reason it can't route around: assemble the full draft or diff, present it in this response,
and stop. Only create or update the file after the user has replied approving it in this same
conversation — a later, ordinary turn, not this skill continuing on its own. Don't shell out via
`Bash` (e.g. a `cat > AGENTS.md` heredoc) to work around the missing Write/Edit access — that
would defeat the whole point of the restriction.

## Step 1 — mode detection

Find the repo's canonical agent doc and branch on it, from the detector's two signals (Step 2 —
run it first if needed): `HAS_AGENTS_MD`, and `HAS_CLAUDE_MD`, which is empty (absent),
`symlink:<target>` (a symlink, normally to `AGENTS.md`), or `file` (a real file). This yields
three modes, not one check run twice. `AGENTS.md` is always the target; a
mature repo's doc is never re-distilled back into the abstract rules — that direction is the
design's cardinal rule. Repo-domain sections (anything without a lineage line — see Step 4) are
never touched or regenerated in any mode; report them "exists, not reviewed."

- **Draft mode** — neither `AGENTS.md` nor a real `CLAUDE.md`. Build a full instantiation from
  scratch (Steps 4–5).
- **Update mode** — `AGENTS.md` exists (a `CLAUDE.md` symlink pointing at it is its expected
  companion, not a second doc). Reconcile it in place (Step 6): diff already-composed sections,
  augment missing ones, surface contradictions.
- **Migrate mode** — a _real_ `CLAUDE.md` exists with no `AGENTS.md` (a legacy or
  non-Claude-tool layout). Never silently draft a parallel `AGENTS.md` beside it. Read the
  `CLAUDE.md`, treat it as the existing canonical doc, reconcile it exactly as Update mode does
  (Step 6), and propose renaming it to `AGENTS.md` plus the `CLAUDE.md → AGENTS.md` symlink
  (Step 7) — the vendor-neutral `AGENTS.md` becomes canonical, `CLAUDE.md` never stays the real
  file.

## Step 2 — run the detector

Run `${CLAUDE_SKILL_DIR}/scripts/detect.sh` via Bash from the repo root and parse its `KEY=value`
output. It's read-only and best-effort per field — a missing tool or unmet precondition blanks
only that field, not the rest. Two fields are inferred guesses, not facts — present them as
"detected, please confirm" rather than asserting them:

- **`BRANCH_MODEL`** — its own output says so.
- **`SCOPES`** — derived from Conventional-Commit history, most-used first, so the low-count tail
  is the prune candidate. Confirm the meaningful set and drop one-off/typo scopes (a `readme` or
  `deploy` used once) before filling git.md's `<scopes>` placeholder.

## Step 3 — read the applicable rule files

GATE-select by the detected facts: `git.md` always (its own GATE is a near-tautology); `github.md`
only if `REMOTE_HOST=github.com`; `go.md` only if `IS_GO_REPO=true`; any
`platform/private/*.md` present. Read each file's COMPOSE block (or its whole content, for
`github.md`, which has none of its own — see Step 4).

## Step 4 — instantiation engine (Draft mode)

Per applicable COMPOSE-bearing file, fill its `<placeholders>` with the detected facts and emit
its section with two things this repo's own `AGENTS.md` uses as the literal template to match:

- A blockquote lineage line: `> Concrete realization of **git.md** (...) for this repo: ...`
- The shared "Precedence: this repo's own docs win over the generic files" section, once, near
  the top of the doc — not repeated per section.

Two traps, both real and both present in this repo's own `AGENTS.md`:

- **`github.md` has no COMPOSE block of its own** ("`git.md` owns everything composable" is
  literally its own text). Its content folds into the _same_ git.md-derived sections instead of
  becoming a separate parallel "GitHub section" — this repo's own "Local tooling" and
  "Credentials" sections each cite both files under one blockquote. Don't emit a
  `github.md`-only section.
- **`BRANCH_MODEL` no longer selects between two models — `git.md` documents exactly one.**
  #128 consolidated `git.md` off its old long-lived-working-branch + squash-merge default onto
  short-lived-feature-branch + rebase-merge; that's now its only Branch & PR model, fully
  fillable via `<protected-branch>`. Always instantiate it mechanically regardless of what
  `detect.sh`'s heuristic finds — the CI signal it looks for (`pr-guards.yml`'s pattern: gating
  PRs on a single-commit count and a Conventional Commit subject) only affects _confidence_, not
  which prose to emit. Signal found: the model is CI-enforced here — this repo's own `AGENTS.md`
  is the worked example, citing `git.md`'s model directly with `pr-guards.yml` as the
  confirmation. Signal absent: instantiate the same section, but flag to the user that no CI
  signal confirms enforcement is actually wired up yet, so they should double-check it or wire
  it up rather than assume the section describes something already enforced.

### Pointer-form for enforced specs

AGENTS.md is the signpost, an enforcing config is the spec — don't let instantiation duplicate
one into the other. This is "restate → point", not "enforced → delete": only the exact
enumerable detail (a type list, a regex, a threshold) that a detected config already defines
moves to pointer-form; the _why_ and the _workflow shape_ around it stay as prose regardless,
since no config file can hold either.

- When `COMMIT_FORMAT_ENFORCEMENT` is non-empty, instantiate git.md's Commits section's type
  list as a pointer instead of enumerating it: `` `type` is a Conventional Commit type (enforced
by `<file from COMMIT_FORMAT_ENFORCEMENT>`; see it for the exact list) `` — keep the rest of
  that sentence (subject length, imperative mood, body wrap, `Co-authored-by`) as prose exactly
  as git.md documents it, since nothing detected here confirms a config checks those specific
  points too. When `COMMIT_FORMAT_ENFORCEMENT` is empty, fall back to the full literal type list
  from git.md — there's nothing to point at, and per the "restate → point, not delete" rule an
  unenforced repo still needs the spec written out somewhere.
- Note whether the enforcement has a local mirror (`COMMIT_FORMAT_ENFORCEMENT`'s "local mirror"
  vs "CI-only" suffix) in the pointer sentence — a CI-only gate is a slow, late loop, so say so
  rather than implying a fast local check exists.
- This same pointer-vs-restate judgment applies to any other COMPOSE-bearing content that
  enumerates a config-defined value — the type list is the one concrete case detect.sh names
  today, not the only one that could exist. Workflow _shape_ (step ordering, when to squash, when
  to open a PR) is never a target for this — it stays prose even when a slow/CI-only gate
  enforces it downstream, per git.md's own guidance, since no config teaches that shape ahead of
  time.

## Step 5 — repo-domain TODO-skeleton (Draft mode)

For sections with no abstract source — what this repo is, its philosophy, structure &
conventions, how to verify changes — emit skeleton headers with a one-line prompt each, seeded
by light, cheap reads (root `README`, package manifests, top-level directory names). Explicit
`<!-- TODO: ... -->` markers, never invented narrative. This is deliberately
narrower than `/init`'s full codebase analysis — point the user at `/init` if they want deeper
codebase-derived drafting of these sections.

Include one `<!-- TODO: name a real exemplar file and a real anti-pattern file for pattern X -->`
line per notable convention you can identify a pattern for, but don't try to auto-select which
files qualify — that's a judgment call prone to false positives, left to the human.

## Step 6 — Update mode (reconcile an existing doc)

Read the existing canonical doc (the `AGENTS.md`, or the real `CLAUDE.md` in Migrate mode). Do
three things, never overwriting hand-authored repo-domain prose:

1. **Diff composed sections.** For each section carrying a lineage blockquote (Step 4), recompute
   what Step 4 would produce today and propose only that diff — with one carve-out: the commit
   `<scopes>` list is _augment-only_. A doc's curated scope list is human refinement, not drift;
   propose _adding_ a scope that commit history shows but the list omits, and never propose
   removing or re-widening a narrower curated set. (Without this, the history-ordered `SCOPES`
   field would re-suggest every pruned scope on each run.)
2. **Augment missing sections.** For each COMPOSE-derived section an applicable rule (Step 3)
   would emit — for git.md + github.md: commit conventions, the Branch & PR model, local tooling,
   credentials — that has _no_ corresponding section in the doc, propose _adding_ it, the same
   output Draft mode would emit, inserted without disturbing what's already there. Judge coverage
   per-section, not per-rule-file: a doc with a Commit-style section but no Branch & PR section is
   _partially_ instantiated, and the absent section still gets offered. This is the path for a
   hand-written `AGENTS.md` that predates the rules, or documents only part of one.
3. **Surface contradictions, don't overwrite them.** If a hand-authored section contradicts a
   rule you'd instantiate, do not silently replace it — under LOCAL-WINS the repo is _allowed_ to
   override. Report it with that framing and offer the choice: **adopt** the rule's semantics
   (replace the section with the instantiation), or **keep the override** — in which case propose
   adding an override marker so the decision is recorded and never re-litigated:

   `> Overrides **<rule>.md** § <topic> — reason: <why>. Deliberate; do not reconcile to the rule.`

   A section already carrying that marker is a settled override: leave it, don't re-offer. The
   marker is the sibling of Step 4's lineage line — one says "derived from a rule," the other
   "deliberately departs from one" — and `audit-rules` reads the same marker to tell a deliberate
   override from accidental drift.

## Step 7 — CLAUDE.md bridge

Unless `HAS_CLAUDE_MD` already starts with `symlink:`, propose (don't create) a gitignored
`CLAUDE.md → AGENTS.md` symlink at the repo root, matching this repo's own pattern — mention it as
a suggested follow-up step in the presented draft, not something written now. (In Migrate mode
that means replacing the real `CLAUDE.md` with the symlink once it has become `AGENTS.md`.)

## Step 8 — present and wait

Assemble the full draft (Draft mode) or the reconciliation — diffs, augment additions, and
contradiction choices (Update/Migrate mode) — directly in this response. State plainly: "This is
a proposal — nothing has been written to disk. Confirm and I'll create/update the file." Stop
there.

## Not in scope for v1

Two bullets from this skill's epic are deliberately deferred to follow-up issues, not built
here: auto-_detecting_ exemplar/anti-pattern files (the TODO-prompt version in Step 5 is the
cheap in-scope substitute), and translating permission-like prose into `settings.json`
allow/deny entries (genuinely underspecified — real scope creep for a first version).
