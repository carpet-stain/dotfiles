# 8. Agent-config rules architecture: layered tree with GATE / LOCAL-WINS / COMPOSE

Date: 2026-07-10

## Status

Accepted

## Context

Agent-config guidance had grown into a single monolithic per-repo
`CLAUDE.md`/`AGENTS.md` mixing three incompatible things: universal philosophy
(true everywhere), language/platform conventions (true for some repos), and
repo-specific facts (true for one repo) (claude/README.md "Why this exists").
Mixing them blocked reuse — the philosophy couldn't be lifted into another repo
without dragging repo facts along — and injected wrong context into the agent,
e.g. Go rules in a Python repo or one platform's commands in an unrelated repo
(claude/README.md "Why this exists").

The earlier fix was a thin `CLAUDE.md` loader that `@import`ed scoped fragments,
each self-gating via an APPLY guard (891a9247). But the `@import` path couldn't
expand env vars, so it had to match the deploy target exactly — a real fragility
(d5dc3e9b). One file (`philosophy.md`) also grew across design principles,
engineering practice, AI-collaboration, and prose style until the removal test
was no longer usable per topic (a9375f8d).

The decision was forced 2026-07-10 when Claude Code's native recursive
`~/.claude/rules/` discovery made a loader unnecessary (d5dc3e9b) and the split
into topical files landed (a9375f8d) — both commits dated 07-10, matching this
decision date.

## Decision

Adopt a layered global rules tree deployed as one recursive symlink into
`~/.claude/rules/`, which Claude Code auto-discovers and loads (issue #94;
d5dc3e9b). Files group by breadth: `universal/` (always), `domain/` (a class of
codebase, e.g. layered apps), `tools/` (git, go), `platform/` (github, plus a
gitignored `private/` for work-internal hosts) (claude/README.md "How the files
are organized").

Load-all-then-gate: every file loads in every session and enforces its own scope
after loading via named GATE / LOCAL-WINS / COMPOSE blocks the agent evaluates
against the current repo (issue #94; claude/README.md "The model"). `go.md` is
the one exception — it uses Claude Code's native `paths:` frontmatter, since "is
this a Go file" is a crisp per-file glob a path gate expresses directly
(79ef5e25).

COMPOSE instantiates a tool/platform file's `<placeholders>` into a
self-contained repo-local `AGENTS.md` (propose-don't-create); the abstract stays
the source and goes inert for that repo after composition (claude/README.md
"COMPOSE"). There is no loader file and no index — drop a file in the right
directory and it loads (d5dc3e9b; claude/README.md "Deployment").

## Alternatives considered

- **Per-repo copies of the rules (whitelist / opt-in per repo)** — duplicates
  the philosophy into every repo and blocks reuse, the exact monolith problem
  this replaces (claude/README.md "Why this exists"). Load-all-then-gate is
  deliberately a blacklist, not a whitelist: only a few broad files match most
  work, so loading them all is a small fixed cost with zero per-repo wiring;
  revisit and switch to a whitelist only if many niche files accumulate later
  (claude/README.md "The model").
- **Conditional / opt-in loading instead of load-all-then-gate** — most gates
  have no path signal to hook into: GitHub-origin and platform-tooling checks
  can only be soft (the model honors GATE prose; the bytes load either way)
  (claude/README.md "The model"; 79ef5e25). Load-all keeps zero per-repo wiring
  — drop a file in the tree and it loads, no index to sync (d5dc3e9b;
  claude/README.md "Deployment"). Where a crisp path signal does exist, `go.md`
  takes the structural `paths:` gate instead (79ef5e25).
- **A `CLAUDE.md` loader that `@import`s scoped fragments** — the prior design
  (891a9247). `@import` can't expand env vars, so the import path had to match
  the deploy target exactly — a fragility that broke on path drift. Claude
  Code's native recursive `~/.claude/rules/` discovery removed the need for any
  loader file or import list, so the loader and `fragments/` dir were dropped
  (d5dc3e9b).
- **One monolithic `philosophy.md` file** — it grew into design principles,
  engineering practice, AI-collaboration, and prose style all at once, making
  the removal test unusable per topic (a9375f8d; claude/README.md "Why split at
  all"). Split into topical `universal/` files, each independently short.

## Consequences

Adding a rule needs zero wiring — a new file, or a whole directory (`domain/`
was added exactly this way at #94), inside the symlinked tree loads with no
deploy-script or index edit (claude/README.md "Deployment"). A GitLab repo can
reuse the same `git.md` baseline with a `gitlab.md` beside it, because
VCS-agnostic and host-specific concerns are split (a9375f8d).

Two costs stay real. Gating is soft for prose-gated files — the bytes load
regardless; only `go.md`'s `paths:` gate is structurally absent until a Go file
is read (79ef5e25; claude/README.md "The model"). And long files weaken
adherence, so files stay few and short, enforced by the removal test
(claude/README.md "Why the rule files are terse", "Maintenance discipline"). The
`audit-rules` skill later automated the sprawl sweep, but that skill and
`compose-agents` are recorded separately (ADR 0012) — they postdate this
decision.

LOCAL-WINS is enforced redundantly (each file's block + the repo's `AGENTS.md`
claim + the COMPOSE line + Claude Code's native load order), so no single soft
instruction is load-bearing (claude/README.md "Local-wins precedence"). Revisit
the load-all blacklist if many niche files accumulate — a whitelist scales
better then (claude/README.md "The model").
