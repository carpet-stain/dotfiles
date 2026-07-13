# Claude Code Agent Configuration

Reusable agent instructions for [Claude Code](https://claude.ai/code), designed so
**abstract engineering philosophy is written once and inherited by every project**, while
language-, platform-, and repo-specific detail stays scoped to where it actually applies.

## Why this exists

A single monolithic `CLAUDE.md`/`AGENTS.md` per repo mixes three incompatible things:

1. **Universal philosophy** — how I want code designed, tested, and shipped. True everywhere.
2. **Language/platform conventions** — Go idioms, a hosting platform's mechanics. True for _some_ repos.
3. **Repo-specific facts** — commands, paths, branch names. True for _one_ repo.

Mixing them blocks reuse (you can't lift the philosophy into another repo without dragging repo
facts along) and injects **wrong context** into the agent (Go rules in a Python repo, one
platform's commands in an unrelated repo). This setup keeps them apart.

## How the files are organized

`claude/rules/` groups files by how broadly they apply — the directory name is the scope, nothing
to cross-reference:

| Directory                   | File                          | Applies to                                   | Loading                                                     |
| --------------------------- | ----------------------------- | -------------------------------------------- | ----------------------------------------------------------- |
| `rules/universal/`          | `design-principles.md`        | How code/tools are shaped                    | Always applies                                              |
|                             | `engineering-practices.md`    | How work gets done (testing, docs, security) | Always applies                                              |
|                             | `ai-collaboration.md`         | How the agent operates                       | Always applies                                              |
|                             | `communication.md`            | What gets said/written                       | Always applies                                              |
| `rules/domain/`             | `architecture.md`             | Building a layered application               | Self-gates on being a layered app                           |
| `rules/tools/`              | `git.md`                      | Any git repo, any host                       | Always applies (trivial gate)                               |
|                             | `go.md`                       | Go repos only                                | Native `paths:` frontmatter — loads only on `go.mod`/`*.go` |
| `rules/platform/`           | `github.md`                   | GitHub-hosted repos only                     | Self-gates on github.com origin                             |
| `rules/platform/` (private) | _(machine-local, gitignored)_ | Repos on a given hosting platform            | Self-gates on that platform's tooling                       |
| _(in each repo)_            | `AGENTS.md` + `docs/`         | One repo only                                | Repo's own files                                            |

Roughly ordered by breadth: universal (every project) → domain (a class of codebase, e.g. a
layered application) → tools (git/language) → platform (host) → repo (this one). A specificity
gradient, not a numbered system: every file's gate is evaluated independently, so a file that
documents itself as "assuming X" (`github.md` assumes `git.md`) is a trusted relationship, not a
mechanically checked one.

There is no loader file. The whole `rules/` tree deploys as a single symlink into Claude Code's own
`$CLAUDE_CONFIG_DIR/rules/`, which it auto-discovers and loads recursively in every project. Drop a
file into the right directory and it loads — nothing to wire. Private or work-internal platform
files are deliberately **not committed** here — see [Private files](#private-files-workinternal-platform-files).

**Why split at all, rather than one file?** Two reasons a monolith can't give. Topical files keep
each one focused enough that the removal test (below) stays usable — easy to ask "does
`design-principles.md` earn every line," hard to ask it of a file that's also about testing, AI
conduct, and prose. And separating `git.md` (branching philosophy true on any host) from `github.md`
(`gh`, Actions, squash-merge behavior specific to one host) lets a GitLab repo reuse the same
`git.md` baseline with a `gitlab.md` beside it.

## The model: load-all, then self-gate — except where a native gate exists

Most files load in **every** project; scope is enforced _after_ loading, by named blocks at the top
of each file the agent evaluates against the current repo — **GATE** (when the file applies),
**LOCAL-WINS** (a repo's own doc beats it on overlap), and, for tools/platform files, **COMPOSE**
(how to instantiate it). A file carries only the blocks it needs. The GATE conditions:

- `universal/` → apply always (no gate).
- `domain/architecture.md` → only when the repo builds a layered application; a soft prose GATE like
  `github.md`, since there's no crisp path signal for "is this a layered app."
- `git.md` → if this repo uses git (nearly always — a rare-exception gate, not a real filter).
- `github.md` → only if the repo's origin is GitHub; otherwise ignored.
- a private platform file → only if that platform's tooling is present; otherwise ignored
  (emphatically — its commands are _wrong_ elsewhere, not merely unnecessary). Distinct platforms are
  mutually exclusive per repo, each gating on its own tooling.

`go.md` is the exception: it uses Claude Code's native `paths:` frontmatter instead of a prose guard,
because "is this a `.go`/`go.mod` file" is a crisp per-file signal a glob expresses directly — unlike
GitHub-origin or platform-tooling checks, which have no path to hook into.

This is a **blacklist** (load everything, exclude what doesn't fit), not a whitelist (opt-in per
repo). Worth it because only a few broad files match most of my work, so loading them all is a
small, fixed cost with **zero per-repo wiring**. If many niche files accumulate later, revisit —
whitelist scales better then. Two honest caveats:

- **Soft gating.** For prose-gated files, exclusion works because the model honors the GATE text, not
  because the file is structurally absent — reliable for crisp guards ("not GitHub → ignore"), but
  still soft, and the file's bytes load either way. `go.md`'s `paths:` gate is the sturdier kind:
  structurally absent until Claude reads a Go file, then loaded for that session. Prefer a path gate
  wherever one fits; not every gate can be one.
- **Cost is in length, not count.** Loading a handful of files every session is cheap; a _long_ file
  is not — verbosity itself reduces adherence, so the files stay few and short. See
  [Why the rule files are terse](#why-the-rule-files-are-terse).

## Local-wins precedence

When an applied file overlaps a repo's own docs, **the repo wins**. Enforced redundantly so no
single soft instruction is load-bearing:

1. Each file's LOCAL-WINS block says "if the repo has its own doc, prefer it; treat this as baseline."
2. The repo's committed `AGENTS.md` independently claims authority for its `docs/`.
3. (For composed repos) the COMPOSE step writes that precedence line into the repo.
4. Natively, Claude Code loads user-level rules _before_ a repo's own
   `CLAUDE.md`/`.claude/rules/`, so the repo's files come later and carry higher
   priority — load-order backing for local-wins. Still context, not hard
   enforcement (only a hook enforces), but the one reinforcement that isn't soft prose.

The `universal/` files are the exception: a repo never _overrides_ them — a repo's `DESIGN.md`
_illustrates_ how the principles are realized there. Illustrate, don't replace.

## COMPOSE, and why the duplication is deliberate

`git.md` and a platform file are **templates** with literal `<placeholders>` (scopes, branch names);
`go.md` has softer abstractions ("your linter"). When a repo _lacks_ a concrete doc for one, the
file's COMPOSE block tells the agent how to distill a repo-specific doc (e.g. `docs/CODING.md`, an
`AGENTS.md` section) by filling in the real nouns, then wire the precedence line. Default is
**propose-don't-create** — the agent suggests and waits before writing committed files. `github.md`
has no `<placeholders>` and no COMPOSE block (`git.md` owns everything composable); the `universal/`
files have none either — a standard is applied, not instantiated.

The result **duplicates**: a composed repo's `AGENTS.md` is a _full instantiation_ of the abstract —
it restates the structure with the repo's nouns, so the abstract (always loaded) and the local
restatement sit in context together. That's deliberate, for two reasons:

- **Self-containment.** The local doc must be correct for a reader with none of these global files —
  another contributor, CI, an agent on a different machine. A public repo's `AGENTS.md` can't assume
  `$CLAUDE_CONFIG_DIR` is loaded behind it, so it restates the generic structure rather than pointing
  at a file the reader may not have.
- **Uncomposed repos.** The abstract earns its keep in repos that have _no_ `AGENTS.md` yet — there
  it's the whole guidance. Composed repos tolerate the overlap; that's the price of the abstract being
  universally present.

Duplication's only real danger is divergence — two statements of the branch model drifting apart. The
guard is _direction_: the abstract is the **source**, the local doc is **derived from it** by COMPOSE,
and the abstract goes **inert** for that repo afterward (it was distilled _from_ that repo and must
not be fed back). Change a convention in one place — the abstract — and re-compose; never hand-edit
the instantiated structure expecting it to flow back. One source, one derived artifact.

## Deployment (Strict XDG)

Claude Code defaults to `~/.claude`, which violates this repo's Zero-Home-Presence rule. Instead,
`zsh/.zshenv` exports:

```sh
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
```

and the deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) symlink the **whole `rules/` tree**,
the **`agents/`** tree, and the **`skills/`** tree as units, plus the global `settings.json`:

```text
claude/rules/                → $XDG_CONFIG_HOME/claude/rules/
claude/agents/               → $XDG_CONFIG_HOME/claude/agents/
claude/skills/               → $XDG_CONFIG_HOME/claude/skills/
claude/settings.json         → $XDG_CONFIG_HOME/claude/settings.json
```

Claude Code reads `$CLAUDE_CONFIG_DIR/rules/` recursively — every `*.md` under it loads at launch with
no index file and nothing to keep in sync when a file is added, renamed, or moved. Edit a source file
here → the symlink reflects it → every project inherits the change, with nothing copied. Adding a whole
new directory (the `domain/` scope was added exactly this way) needs no deploy-script edit — it's
already inside the symlinked tree.

`claude/settings.json` is unrelated to the rule files — it's Claude Code's own top-level config
(telemetry, error reporting, auto-update), kept here and symlinked so it's version-controlled instead
of a manual one-off edit.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`, for the
> dotfiles repo's _own_ agent guidance) which is gitignored.

## Subagents (`claude/agents/`)

Alongside the always-loaded `rules/`, `claude/agents/` holds Claude Code **subagents** — specialized
assistants the main agent delegates to for a bounded job, each with its own context, system prompt,
tools, and model. `agents/` deploys exactly like `rules/`: one directory symlink to
`$CLAUDE_CONFIG_DIR/agents/`, discovered recursively, with no per-agent wiring. A subagent is **not**
always-on context — it loads only when delegated to, so it costs nothing until used.

- **`backlog-manager`** — a project-manager / ticket specialist that owns GitHub issue and backlog
  work: writing, labeling, prioritizing, grooming, and driving issues. Repo-agnostic — it reads each
  repo's labels and conventions at runtime rather than hardcoding them — and uses project-scoped memory
  to retain a repo's backlog knowledge across sessions. Delegate by mentioning issues/backlog, by name,
  or run a dedicated session with `claude --agent backlog-manager`.

### Subagent memory: tracked, and split by portability

A subagent's project-scoped memory (`.claude/agent-memory/<name>/`) is tracked, not gitignored —
it's the durable half of "write it down over memory," version-controlled like everything else the
subagent's judgment shapes. The dividing line from the subagent's own definition
(`claude/agents/<name>.md`) is portability: a rule that would hold for this subagent in _any_ repo
belongs in the definition — hand-reviewed, symlinked everywhere the agent runs; a fact specific to
_this_ repo (issue numbers, this repo's label scheme, this user's preferences) stays in memory.
Within the memory tier, commit it whole — no further split between "doc-like" and "notes about the
user" files, complexity a solo repo doesn't need.

The subagent itself never commits memory — `backlog-manager` has no git access, and its lane stops
at issues/labels/memory content, not repo mutation. Whoever's in the repo commits it
opportunistically, batched at the end of a substantive session or after a grooming sweep, not
per-tweak: one low-ceremony `chore(claude): sync <agent> memory` through the normal branch → draft
PR → squash → rebase-merge flow — memory isn't code, but it's small enough that a dedicated
lighter lane isn't worth the extra mechanism. Memory files are heredoc-authored working notes, not
published prose, so `.claude/agent-memory/**` is excluded from the markdownlint/prettier hooks —
same treatment as `CHANGELOG.md`.

## Skills (`claude/skills/`)

A Skill is on-demand, not always-on: Claude Code invokes it by name (`/skill-name`) or
auto-invokes it when its `description` matches the request, and it costs nothing outside that.
That's the deciding difference from a subagent — a subagent earns its place only when
persistent memory, repeated delegation, _and_ context isolation all apply together; a one-shot
analysis with none of those is a skill, not a subagent. `skills/` deploys exactly like `rules/`
and `agents/`: one directory symlink to `$CLAUDE_CONFIG_DIR/skills/`, with each skill's
`SKILL.md` living at `skills/<name>/SKILL.md`, discovered recursively, no per-skill wiring.
Skills are repo-agnostic and don't GATE the way rules do — a skill either fires on request or it
doesn't, there's nothing to self-gate against a repo's shape.

- **`audit-rules`** — reads `$CLAUDE_CONFIG_DIR/rules/` and reports contradictions (two
  directives that disagree) and sprawl (files over ~200 lines or spanning more than one topic).
  Propose-don't-apply, enforced structurally: it has no Write/Edit access, so it can only report
  findings, never act on them.
- **`compose-agents`** — the opposite direction: drafts or updates a repo's `AGENTS.md` by
  instantiating each applicable rule file's COMPOSE block with facts detected from the repo
  (branch model, version scheme, scopes, pre-commit tooling). Propose-don't-create: it presents
  a full draft or diff in chat and waits for approval before anything is written.

## Private files (work/internal platform files)

Some platform files describe **internal or employer-owned tooling** (hostnames, CLIs, build systems)
that must **never** land in this public repo. They live in one gitignored directory —
`claude/rules/platform/private/` — so a new one is safe **by default**: dropping a file in there is
enough, with no per-file `.gitignore` edit to remember and get wrong.

1. **Write the file** at `claude/rules/platform/private/<name>.md`, with its own GATE and LOCAL-WINS
   blocks, exactly like a committed platform file.
2. **Nothing else.** The directory is gitignored as a whole, so the file can't be committed by
   accident. `rules/` is already symlinked as one tree and discovered recursively, so the file loads
   into `$CLAUDE_CONFIG_DIR/rules/` with no deploy-script or gitignore wiring.

**Why a whole ignored directory, not a per-file ignore line:** naming each private file in
`.gitignore` means one forgotten line leaks internal tooling into a public repo — the exact disaster
this mechanism prevents — and it spells the private file's name out in the public `.gitignore`
besides. A directory ignored wholesale is safe the instant a file lands in it, and names nothing.

**On a fresh clone** (or any machine lacking the files) `platform/private/` is simply empty — the
symlink still resolves, the public files load normally, with zero internal leakage. On a machine that
needs one, drop the file in `private/`; no re-deploy, the directory symlink is already there.

## How it behaves per repo (worked examples)

| Repo                                           | universal | domain(arch)                  | go                           | git                 | github                       | private platform                 | Net effect                                                           |
| ---------------------------------------------- | --------- | ----------------------------- | ---------------------------- | ------------------- | ---------------------------- | -------------------------------- | -------------------------------------------------------------------- |
| Go + internal platform, rich docs              | applies   | gates on; DESIGN.md shows how | gates on, but CODING.md wins | applies, baseline   | gates off (private platform) | gates on, but OPERATIONS.md wins | local docs authoritative; files baseline                             |
| New Go µ-service on internal platform, no docs | applies   | gates on, fully used          | gates on, fully used         | applies, fully used | gates off                    | gates on, fully used             | files carry conventions from day one                                 |
| Python service on GitHub                       | applies   | gates on (layered app)        | gates off (no go.mod)        | applies             | gates on                     | gates off                        | universal + arch + git + GitHub, no Go leakage                       |
| GitHub OSS (Go)                                | applies   | gates on                      | gates on                     | applies             | gates on                     | gates off (emphatic)             | universal + arch + Go + git + GitHub, zero internal-platform leakage |
| Dotfiles / config repo (this one)              | applies   | gates off (no layers)         | gates off (no go.mod)        | applies             | gates on                     | gates off                        | universal + git + GitHub; no architecture or Go doctrine loaded      |

## Authoring rules for these files

- **`universal/`, `domain/`, and `tools/` must contain no repo-specific nouns** — no paths, branch
  names, service names. `domain/` is philosophy like `universal/` (illustrated, never overridden, no
  COMPOSE); `tools/` may name Go/git tools and idioms; a `platform/` file may name that platform's
  tools but keeps repo values as `<placeholders>`.
- **References are one-directional**: a repo may point at a file here; a file
  here must never point at a specific repo. A `platform/` file may point at
  its `tools/` baseline (`github.md` → `git.md`).
- **Never commit an internal/work platform file to a public repo** — keep it as a
  [private file](#private-files-workinternal-platform-files).

## Why the rule files are terse

The `rules/` files are directives, not essays. They load into **every** session, and Claude Code's own
guidance is blunt: files over ~200 lines cost context and _reduce_ adherence — the more concise the
instruction, the more reliably it's followed. So the files hold themselves to `communication.md`'s own
standard (terse, concrete, lead with the point) instead of exempting themselves from it.

The split that keeps them lean:

- **Directive vs. rationale.** The always-loaded file carries the _what_. The _why_ lives here in the
  README (which loads _never_) when a reader would need it, or is cut entirely when it's generic
  engineering knowledge the model already has ("write the minimum code" doesn't need three sentences
  defending it). Non-obvious _why_ that changes behavior stays inline (e.g. force-push aborts if the
  remote moved).
- **No restatement.** A closing "Before Finishing" checklist that re-lists the
  file's own principles is pure duplication; it's compressed to a handful of
  cross-cutting checks in `ai-collaboration.md`, not repeated per file.

A pass in this spirit took the always-loaded set (universal + `git.md`) from
~390 to ~250 lines with no directive lost — proof that most of the length was
justification, not instruction.

**AGENTS.md gets a different, higher threshold.** It's not a rules file — it's the composed
per-repo guide, legitimately carrying domain sections (what-this-is, structure, verification)
none of the files above have, so the ~200 cap would false-positive constantly. Its own signal:
soft-warn past ~250 lines, firmly flag past ~300. Past that point the usual cause is the same
sprawl the rules files fight — restated enforcement or unpruned topic overlap — so `audit-rules`
treats a long AGENTS.md as a symptom pointing at those checks, not a bare "too long."

## Maintenance discipline (the removal test)

These files should grow the same way any codebase should: additions earn their place, and nothing sits
there just because it seemed like a good idea once.

- **Add a rule only after it would have prevented an actual mistake** — not because it sounds reasonable
  in the abstract.
- **Remove a rule once it's being followed without being told** — a convention that's now just how
  things are done doesn't need to keep paying rent in every session's context.
- **Audit periodically for contradictions** across these files and against a repo's own docs; two rules
  that disagree mean the model picks one arbitrarily. The `audit-rules` skill automates finding these
  (and length/topic sprawl) — it doesn't replace the judgment calls below, only the sweep.
- **Longer files weaken adherence** — if a file is growing, look for what it's earned the right to keep;
  if it's growing because it covers more than one topic, split it, the way `philosophy.md` split into
  the four `universal/` files. The same test applies to this README: rationale lives here, but it earns
  its place too.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded
`CLAUDE.md` and rules file, so you can confirm the `universal/` files and the
applicable `tools/`/`platform/` files loaded from `$CLAUDE_CONFIG_DIR/rules/`.
Then ask the agent whether each file's GATE fired correctly and whether
local docs win on overlap. For a precise trace of which files loaded, when, and why — the definitive
check that `go.md`'s `paths:` gate fires only on Go files — enable Claude Code's `InstructionsLoaded`
hook, which logs exactly that. The decisive negative test is a repo on none of the gated
platforms/languages — only the `universal/` files should apply.
