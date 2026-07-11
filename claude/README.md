# Claude Code Agent Configuration

Reusable agent instructions for [Claude Code](https://claude.ai/code), designed so
**abstract engineering philosophy is written once and inherited by every project**, while
language-, platform-, and repo-specific detail stays scoped to where it actually applies.

## Why this exists

A single monolithic `CLAUDE.md`/`AGENTS.md` per repo mixes three incompatible things:

1. **Universal philosophy** — how I want code designed, tested, and shipped. True everywhere.
2. **Language/platform conventions** — Go idioms, a hosting platform's mechanics. True for *some* repos.
3. **Repo-specific facts** — commands, paths, branch names. True for *one* repo.

Mixing them blocks reuse (you can't lift the philosophy into another repo without dragging
repo facts along) and injects **wrong context** into the agent (Go rules in a Python repo,
one platform's commands in an unrelated repo). This setup keeps them apart instead.

## How the files are organized

`claude/rules/` groups files by how broadly they apply — the directory name tells you the
scope, nothing to cross-reference:

| Directory | File | Applies to | Loading |
|-----------|------|-----------|---------|
| `rules/universal/` | `design-principles.md` | How code/tools are shaped | Always applies |
| | `engineering-practices.md` | How work gets done (testing, docs, security) | Always applies |
| | `ai-collaboration.md` | How the agent operates | Always applies |
| | `communication.md` | What gets said/written | Always applies |
| `rules/domain/` | `architecture.md` | Building a layered application | Self-gates on being a layered app |
| `rules/tools/` | `git.md` | Any git repo, any host | Always applies (trivial gate) |
| | `go.md` | Go repos only | Native `paths:` frontmatter — loads only on `go.mod`/`*.go` |
| `rules/platform/` | `github.md` | GitHub-hosted repos only | Self-gates on github.com origin |
| `rules/platform/` (private) | *(machine-local, gitignored)* | Repos on a given hosting platform | Self-gates on that platform's tooling |
| *(in each repo)* | `AGENTS.md` + `docs/` | One repo only | Repo's own files |

Roughly ordered by how broadly each applies: universal (every project) → domain (a class of
codebase, e.g. a layered application) → tools (git/language-specific) → platform (hosting-specific)
→ repo (this one repo) — a specificity gradient, not a formal numbered system. There's no enforced dependency between them: every
file's gate is evaluated independently by Claude Code, so a file that documents itself as
"assuming X" (e.g. `github.md` assumes `git.md`) is a documented, trusted relationship, not a
mechanically checked one.

There is no loader file. The whole `rules/` tree deploys as a single symlink straight into
Claude Code's own `$CLAUDE_CONFIG_DIR/rules/` directory — a first-class, user-level mechanism
it already auto-discovers and loads recursively, unconditionally, in every project. Dropping a
file into the right directory gets it loaded; there's nothing to wire.

Private or work-internal platform files are deliberately **not committed** here — see
[Private files](#private-files-workinternal-platform-files) below.

## Why four files under universal/, not one

"Philosophy" used to be a single file until it grew into several unrelated concerns. Splitting
by topic keeps each file focused enough that the removal test (below) is actually usable — it's
easy to ask "does design-principles.md still earn every line" and hard to ask that of a file
that's also about testing, AI conduct, and prose style. Splitting doesn't reduce token cost:
all four still load unconditionally, the same total content as before, just organized instead
of concatenated.

## Why git.md is separate from github.md

The old `github.md` mixed two things: git/branching philosophy that's true on any host (GitHub,
GitLab, Bitbucket, bare git) and mechanics specific to GitHub itself (`gh` CLI, GitHub Actions,
squash-merge carrying the PR title into the commit — a real GitHub behavior, not a universal
git fact). `git.md` owns the first; `github.md` owns the second and assumes `git.md`'s
workflow is already in effect. A GitLab repo would get a `gitlab.md` platform file instead,
reusing the same `git.md` baseline.

## The model: load-all, then self-gate ("blacklist") — except where a native gate exists

Most files load in **every** project; scope is enforced *after* loading, by named blocks at the
top of each file that the agent evaluates against the current repo — **GATE** (when the file
applies), **LOCAL-WINS** (a repo's own doc beats it on overlap), and, for tools/platform files,
**COMPOSE** (how to instantiate it). A file carries only the blocks it needs. The GATE conditions:

- the `universal/` files → apply always (no gate).
- `domain/architecture.md` → applies only when the repo builds a layered application; a soft prose
  GATE like `github.md`, since there's no crisp path signal for "is this a layered app".
- `git.md` → applies if this repo uses git (true for nearly every repo — a rare-exception gate,
  not a real filter).
- `github.md` → applies only if the repo's origin is GitHub; otherwise ignored.
- a private platform file → applies only if that platform's tooling is present; otherwise
  ignored (emphatically — its commands are *wrong*, not merely unnecessary, elsewhere).
  Distinct hosting platforms are mutually exclusive per repo — each gates on its own tooling.

`go.md` is the exception: it uses Claude Code's native `paths:` frontmatter instead of a prose
guard, because "is this file a `.go` file or `go.mod`" is a crisp, per-file signal a glob can
express directly — unlike GitHub-origin or platform-tooling checks, which have no path to hook
into and stay prose-gated.

This is a **blacklist** model (load everything, exclude what doesn't fit) for the prose-gated
files, rather than a whitelist (opt-in per repo). Chosen because there are only a few, broad
files that match most of my work, so the always-loaded token cost is negligible and there
is **zero per-repo wiring** in the common case. If many niche files accumulate later, revisit —
whitelist scales better then.

### Trade-off (be honest)

For the prose-gated files, the gating is **soft**: it works because the model honors the GATE
text, not because the file is structurally absent. Reliability is high for crisp guards ("not
GitHub → ignore"). `go.md` is the sturdier kind — `paths:` frontmatter keeps it out of context
until Claude actually reads a Go file (`go.mod`/`*.go`), loading it only then and for the rest of
that session, in any repo. Where a gate *can* be
expressed as a path pattern, prefer that over a prose guard; not every gate can (GitHub origin,
platform tooling, "uses git at all"), which is why the two mechanisms coexist here.

Soft gating also carries a token cost — gated-off files load anyway — enumerated with the design's
other deliberate cost under [The duplication is deliberate](#the-duplication-is-deliberate).

## Local-wins precedence

When an applied file overlaps a repo's own docs, **the repo wins**. This is enforced
redundantly so no single soft instruction is load-bearing:

1. Each file's LOCAL-WINS block says "if the repo has its own doc, prefer it; treat this as baseline."
2. The repo's committed `AGENTS.md` independently claims authority for its `docs/`.
3. (For composed repos) the COMPOSE step below writes that precedence line into the repo.
4. Natively, Claude Code loads user-level rules before a repo's own `CLAUDE.md`/`.claude/rules/`,
   so the repo's files come later and carry higher priority — load-order backing for local-wins.
   Still context, not hard enforcement (only a hook enforces), but the one reinforcement that
   isn't soft prose.

The `universal/` files are the exception: a repo never *overrides* them — a repo's `DESIGN.md`
*illustrates* how the principles are realized there. Illustrate, don't replace.

## The duplication is deliberate

A composed repo's `AGENTS.md` is a *full instantiation* of the abstract files — it restates their
structure with this repo's concrete nouns, not just the deltas. So the abstract (always loaded) and
the local restatement sit in context together, duplicated. That's deliberate, for two reasons:

- **Self-containment.** The local doc has to be correct for a reader with none of these global files
  — another contributor, CI, an agent on a different machine. A public repo's `AGENTS.md` can't
  assume `$CLAUDE_CONFIG_DIR` is loaded behind it, so it restates the generic structure (commit
  format, PR model) instead of pointing at a file the reader may not have.
- **Uncomposed repos.** The abstract earns its always-on cost in the repos that have *no* `AGENTS.md`
  yet — there it's the whole guidance. Composed repos just tolerate the overlap; that's the price of
  the abstract being universally present.

The removal test doesn't fire on this: a restatement a globals-less reader needs isn't dead weight.
This is one of two token costs the design pays on purpose — collected here so both are visible at
once:

- **Restatement in composed repos** — the local doc duplicates the always-loaded abstract, as
  above. The deliberate trade for a doc that stands on its own.
- **Gated-off files still load** — a prose-gated file (e.g. `github.md` in a non-GitHub repo) costs
  tokens even when its GATE says ignore, because soft gating drops it behaviorally, not
  structurally (see [Trade-off](#trade-off-be-honest)). `go.md`'s `paths:` gate is the exception:
  structurally absent, zero cost, on any turn no Go file is in play — which is why a path gate beats
  a prose guard wherever one fits.

Both are real tokens, both accepted deliberately: self-containment and universal presence buy more
than the bytes.

## COMPOSE (tools and platform files only)

`git.md` and a platform file are **templates** with literal `<placeholders>` (scopes, branch
names); `go.md` has softer abstractions ("your linter"). When a repo *lacks* a concrete doc for
one, the file's COMPOSE block tells the agent how to distill a repo-specific doc (e.g.
`docs/CODING.md`, an `AGENTS.md` section) by filling in the real nouns, then wire the
precedence line. Default is **propose-don't-create** — the agent suggests and waits before
writing committed files.

For a *mature* repo that already has those docs, COMPOSE is **inert**: the file was distilled
*from* that repo and must not be fed back. Only the GATE and LOCAL-WINS blocks fire, deferring to
the existing local docs. `github.md` has no `<placeholders>` of its own and no COMPOSE block —
`git.md` already owns everything that needs composing; `github.md` is pure mechanics.

The `universal/` files have **no** COMPOSE block — a standard is applied, not instantiated.

Duplication's only real danger is divergence — two statements of the branch model that drift apart.
The guard is *direction*: the abstract file is the **source**, the local doc is **derived from it**
by COMPOSE, and the abstract goes inert for that repo afterward. Change a convention in one place —
the abstract — and re-compose; never hand-edit the instantiated structure in a repo's `AGENTS.md`
expecting it to flow back. One source, one derived artifact — not two hand-maintained copies.

## Deployment (Strict XDG)

Claude Code defaults to `~/.claude`, which violates this repo's Zero-Home-Presence rule.
Instead, `zsh/.zshenv` exports:

```sh
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
```

and the deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) symlink the **whole `rules/`
tree** as one unit, the **`agents/`** tree the same way, plus the global `settings.json`:

```
claude/rules/                → $XDG_CONFIG_HOME/claude/rules/
claude/agents/               → $XDG_CONFIG_HOME/claude/agents/
claude/settings.json         → $XDG_CONFIG_HOME/claude/settings.json
```

Claude Code reads `$CLAUDE_CONFIG_DIR/rules/` recursively — every `*.md` anywhere under it
loads at launch with no index file, no import list, and nothing to keep in sync when a file is
added, renamed, or moved anywhere in the tree. Edit a source file here → the symlink reflects
it → every project inherits the change, with nothing copied. Adding a whole new directory (the
`domain/` scope was added exactly this way) needs no deploy-script edit either — it's already
inside the symlinked tree.

`claude/settings.json` is unrelated to the files above — it's Claude Code's own
top-level config (telemetry, error reporting, auto-update), not agent instructions. Kept
here and symlinked the same way so it's version-controlled instead of a manual one-off edit.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`,
> for the dotfiles repo's *own* agent guidance) which is gitignored.

## Subagents (`claude/agents/`)

Alongside the always-loaded `rules/`, `claude/agents/` holds Claude Code **subagents** —
specialized assistants the main agent delegates to for a bounded job, each with its own context,
system prompt, tools, and model. `agents/` deploys exactly like `rules/`: one directory symlink
to `$CLAUDE_CONFIG_DIR/agents/`, where Claude Code discovers every `*.md` recursively, with no
per-agent wiring.

- **`backlog-manager`** — a project-manager / ticket specialist that owns GitHub issue and
  backlog work: writing, labeling, prioritizing, grooming, and driving issues. Repo-agnostic —
  it reads each repo's labels and conventions at runtime rather than hardcoding them — and uses
  project-scoped memory to retain a repo's backlog knowledge across sessions. Delegate by
  mentioning issues/backlog, by name, or run a dedicated session with `claude --agent
  backlog-manager`.

Unlike `rules/`, a subagent is **not** always-on context — it loads only when delegated to, so it
costs nothing until used.

## Private files (work/internal platform files)

Some platform files describe **internal or employer-owned tooling** (hostnames, CLIs, build
systems) that must **never** land in this public repo. They live in one gitignored directory —
`claude/rules/platform/private/` — so a new one is safe **by default**: dropping a file in there
is enough, with no per-file `.gitignore` edit to remember and get wrong.

1. **Write the file** at `claude/rules/platform/private/<name>.md`, with its own GATE and
   LOCAL-WINS blocks, exactly like a committed platform file.
2. **Nothing else.** The directory is gitignored as a whole (`claude/rules/platform/private/`),
   so the file can't be committed by accident. `rules/` is already symlinked as one tree and
   Claude Code discovers `.md` files recursively, so the file loads into
   `$CLAUDE_CONFIG_DIR/rules/` with no deploy-script or gitignore wiring.

**Why a whole ignored directory, not a per-file ignore line:** naming each private file in
`.gitignore` means one forgotten line leaks internal tooling into a public repo — the exact
disaster this mechanism exists to prevent — and it spells the private file's name out in the
public `.gitignore` besides. A directory ignored wholesale is safe the instant a file lands in
it, and names nothing.

**On a fresh clone** (or any machine that lacks the files) `platform/private/` is simply empty
or absent — the symlink still resolves, the public files load normally, with zero internal
leakage. On a machine that needs one, drop the file in `private/`; no re-deploy required since
the directory symlink is already there.

This keeps the public repo clean while letting a work laptop reuse the same dotfiles with its
internal platform file fully wired.

## How it behaves per repo (worked examples)

| Repo | universal | domain(arch) | go | git | github | private platform | Net effect |
|------|-----------|--------------|----|----|--------|------------------|-----------|
| Go + internal platform, rich docs | applies | gates on; DESIGN.md shows how | gates on, but CODING.md wins | applies, baseline | gates off (private platform) | gates on, but OPERATIONS.md wins | local docs authoritative; files baseline |
| New Go µ-service on internal platform, no docs | applies | gates on, fully used | gates on, fully used | applies, fully used | gates off | gates on, fully used | files carry conventions from day one |
| Python service on GitHub | applies | gates on (layered app) | gates off (no go.mod) | applies | gates on | gates off | universal + arch + git + GitHub, no Go leakage |
| GitHub OSS (Go) | applies | gates on | gates on | applies | gates on | gates off (emphatic) | universal + arch + Go + git + GitHub, zero internal-platform leakage |
| Dotfiles / config repo (this one) | applies | gates off (no layers) | gates off (no go.mod) | applies | gates on | gates off | universal + git + GitHub; no architecture or Go doctrine loaded |

## Authoring rules for these files

- **`universal/`, `domain/`, and `tools/` must contain no repo-specific nouns** — no paths, branch
  names, service names. `domain/` is philosophy like `universal/` (illustrated, never overridden,
  no COMPOSE); `tools/` may name Go/git tools and idioms; a `platform/` file may name that
  platform's tools but keeps repo values as `<placeholders>`.
- **References are one-directional**: a repo may point at a file here; a file here must never
  point at a specific repo. A `platform/` file may point at its `tools/` baseline
  (`github.md` → `git.md`).
- **Never commit an internal/work platform file to a public repo** — keep it as a
  [private file](#private-files-workinternal-platform-files).

## Maintenance discipline (the removal test)

These files should grow the same way any codebase should: additions earn their place, and nothing
sits there just because it seemed like a good idea once.

- **Add a rule only after it would have prevented an actual mistake** — not because it sounds
  reasonable in the abstract.
- **Remove a rule once it's being followed without being told** — a convention that's now just how
  things are done doesn't need to keep paying rent in every session's context.
- **Audit periodically for contradictions** across these files and against a repo's own docs; two
  rules that disagree mean the model picks one arbitrarily.
- Longer files cost more context and weaken adherence — if a file is growing, look for what
  it's earned the right to keep before assuming it should just keep growing. If a file is growing
  because it's covering more than one topic, that's a signal to split it, the same way
  `philosophy.md` split into the four `universal/` files.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded `CLAUDE.md` and rules
file, so you can confirm the `universal/` files and the applicable `tools/`/`platform/` files
actually loaded from `$CLAUDE_CONFIG_DIR/rules/`. Then ask the agent to confirm whether each
file's GATE fired correctly for this repo, and whether local docs win on overlap. For a precise
trace of which files loaded, when, and why — the definitive check that `go.md`'s `paths:` gate
fires only on Go files — enable Claude Code's `InstructionsLoaded` hook, which logs exactly that.
The decisive
negative test is a repo on none of the gated platforms/languages — only the `universal/` files
should apply.
