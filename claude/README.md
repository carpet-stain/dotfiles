# Claude Code Agent Configuration

Layered, reusable agent instructions for [Claude Code](https://claude.ai/code),
designed so **abstract engineering philosophy is written once and inherited by every
project**, while language-, platform-, and repo-specific detail stays scoped to where
it actually applies.

## Why this exists

A single monolithic `CLAUDE.md`/`AGENTS.md` per repo mixes three incompatible things:

1. **Universal philosophy** — how I want code designed, tested, and shipped. True everywhere.
2. **Language/platform conventions** — Go idioms, a hosting platform's mechanics. True for *some* repos.
3. **Repo-specific facts** — commands, paths, branch names. True for *one* repo.

Mixing them blocks reuse (you can't lift the philosophy into another repo without dragging
repo facts along) and injects **wrong context** into the agent (Go rules in a Python repo,
one platform's commands in an unrelated repo). This setup separates them into layers.

## The layers

`claude/rules/` is organized into directories that mirror the layer numbers below — the
directory name tells you the scope without cross-referencing this table.

| Layer | Directory | File | Scope | Loading |
|-------|-----------|------|-------|---------|
| **0 — Universal** | `rules/layer0-universal/` | `design-principles.md` | How code/tools are shaped | Always applies |
| | | `engineering-practices.md` | How work gets done (testing, docs, security) | Always applies |
| | | `ai-collaboration.md` | How the agent operates | Always applies |
| | | `communication.md` | What gets said/written | Always applies |
| **1 — Tool** | `rules/layer1-tools/` | `git.md` | Any git repo, any host | Always applies (trivial gate) |
| | | `go.md` | Go repos only | Native `paths:` frontmatter — loads only on `go.mod`/`*.go` |
| **2 — Platform** | `rules/layer2-platform/` | `github.md` | GitHub-hosted repos only | Self-gates on github.com origin |
| **2 — Platform (private)** | *(machine-local, gitignored)* | *(varies)* | Repos on a given hosting platform | Self-gates on that platform's tooling |
| **3 — Repo** | *(in each repo)* | `AGENTS.md` + `docs/` | One repo only | Repo's own files |

There is no loader file. Each `layerN-*/` directory deploys as a single symlink straight into
Claude Code's own `$CLAUDE_CONFIG_DIR/rules/` directory — a first-class, user-level mechanism
it already auto-discovers and loads recursively, unconditionally, in every project. Dropping a
layer file into the right directory gets it loaded; there's nothing to wire.

Platform layers for **private or work-internal** hosting environments are deliberately
**not committed** here — see [Private layer files](#private-layer-files-workinternal-layers) below.

## Why four files at Layer 0, not one

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
git fact). `git.md` (Layer 1) owns the first; `github.md` (Layer 2) owns the second and assumes
`git.md`'s workflow is already in effect. A GitLab repo would get a `gitlab.md` Layer 2 file
instead, reusing the same `git.md` baseline.

## The model: load-all, then self-gate ("blacklist") — except where a native gate exists

Most layer files load in **every** project; scope is enforced *after* loading, by an **APPLY
guard** at the top of the file that the agent evaluates against the current repo:

- the `layer0-universal/` files → apply always (no gate).
- `git.md` → applies if this repo uses git (true for nearly every repo — a rare-exception gate,
  not a real filter).
- `github.md` → applies only if the repo's origin is GitHub; otherwise ignored.
- a private platform layer → applies only if that platform's tooling is present; otherwise
  ignored (emphatically — its commands are *wrong*, not merely unnecessary, elsewhere).
  Distinct hosting platforms are mutually exclusive per repo — each gates on its own tooling.

`go.md` is the exception: it uses Claude Code's native `paths:` frontmatter instead of a prose
guard, because "is this file a `.go` file or `go.mod`" is a crisp, per-file signal a glob can
express directly — unlike GitHub-origin or platform-tooling checks, which have no path to hook
into and stay prose-gated.

This is a **blacklist** model (load everything, exclude what doesn't fit) for the prose-gated
layers, rather than a whitelist (opt-in per repo). Chosen because there are only a few, broad
layer files that match most of my work, so the always-loaded token cost is negligible and there
is **zero per-repo wiring** in the common case. If many niche layers accumulate later, revisit —
whitelist scales better then.

### Trade-off (be honest)

For the prose-gated layers, the gating is **soft**: it works because the model honors the guard
text, not because the layer is structurally absent. Reliability is high for crisp guards ("not
GitHub → ignore"). Every repo pays the token cost of those layers even when gated off.
`go.md` doesn't have this cost — `paths:` frontmatter makes it structurally absent from context
on any turn that doesn't touch a Go file, in any repo. Where a layer's gate *can* be expressed as
a path pattern, prefer that over a prose guard; not every gate can (GitHub origin, platform
tooling, "uses git at all"), which is why the two mechanisms coexist here.

## Local-wins precedence

When an applied layer overlaps a repo's own docs, **the repo wins**. This is enforced
redundantly so no single soft instruction is load-bearing:

1. Each layer file's APPLY guard says "if the repo has its own doc, prefer it; treat this as baseline."
2. The repo's committed `AGENTS.md` independently claims authority for its `docs/`.
3. (For composed repos) the COMPOSE step below writes that precedence line into the repo.

Layer 0 is the exception: a repo never *overrides* it — a repo's `DESIGN.md` *illustrates* how
the principles are realized there. Illustrate, don't replace.

## COMPOSE protocol (Layers 1 & 2 only)

Layers 1 and 2 are **templates**. `go.md` has abstractions ("your linter"); `git.md` and a
platform layer have literal `<placeholders>` (scopes, branch names). When a repo *lacks* a
concrete doc for that layer, the file's COMPOSE protocol tells the agent how to distill a
repo-specific doc (e.g. `docs/CODING.md`, an `AGENTS.md` section) by filling in the real nouns,
then wire the precedence line. Default is **propose-don't-create** — the agent suggests and
waits before writing committed files.

For a *mature* repo that already has those docs, COMPOSE is **inert**: the layer file was
distilled *from* that repo and must not be fed back. Only the APPLY guards fire, deferring to
the existing local docs. `github.md` has no `<placeholders>` of its own and no COMPOSE
protocol — `git.md` already owns everything that needs composing; `github.md` is pure mechanics.

Layer 0 has **no** COMPOSE protocol — a standard is applied, not instantiated.

## Deployment (Strict XDG)

Claude Code defaults to `~/.claude`, which violates this repo's Zero-Home-Presence rule.
Instead, `zsh/.zshenv` exports:

```sh
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
```

and the deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) symlink the **whole `rules/`
tree** as one unit, plus the global `settings.json`:

```
claude/rules/                → $XDG_CONFIG_HOME/claude/rules/
claude/settings.json         → $XDG_CONFIG_HOME/claude/settings.json
```

Claude Code reads `$CLAUDE_CONFIG_DIR/rules/` recursively — every `*.md` anywhere under it
loads at launch with no index file, no import list, and nothing to keep in sync when a file is
added, renamed, or moved anywhere in the tree. Edit a source file here → the symlink reflects
it → every project inherits the change, with nothing copied. Adding a whole new layer tier (a
fourth layer, say) needs no deploy-script edit either — it's already inside the symlinked tree.

`claude/settings.json` is unrelated to the layer system above — it's Claude Code's own
top-level config (telemetry, error reporting, auto-update), not agent instructions. Kept
here and symlinked the same way so it's version-controlled instead of a manual one-off edit.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`,
> for the dotfiles repo's *own* agent guidance) which is gitignored.

## Private layer files (work/internal layers)

Some platform layers describe **internal or employer-owned tooling** (hostnames, CLIs, build
systems) that must **never** land in this public repo. They are kept **machine-local and
gitignored**, yet still load through the same mechanism as everything else here. Because the
whole `rules/` tree is symlinked as one unit, this needs no deploy-script wiring at all:

1. **Write the layer file** inside the appropriate layer directory, e.g.
   `claude/rules/layer2-platform/<name>.md`, with its own APPLY guard, exactly like a
   committed layer. Gitignore it:
   ```gitignore
   claude/rules/layer2-platform/<name>.md
   ```
2. **Deploy.** Nothing to do — `rules/` is already symlinked as a whole tree, so any file
   physically present in the source tree (tracked or not) appears through the symlink and
   Claude Code auto-discovers it.

**On a fresh clone** (or any machine that lacks the file) it's simply absent from the source
directory — the symlink still resolves, the public layers load normally, with zero internal
leakage. On a machine that needs it, drop the gitignored file in place; no re-deploy required
since the directory symlink is already there.

This keeps the public repo clean while letting a work laptop reuse the same dotfiles with its
internal platform layer fully wired.

## How it behaves per repo (worked examples)

| Repo | layer0 | go | git | github | private platform | Net effect |
|------|--------|----|----|--------|------------------|-----------|
| Go + internal platform, rich docs | applies; DESIGN.md shows how | gates on, but CODING.md wins | applies, baseline | gates off (private platform) | gates on, but OPERATIONS.md wins | local docs authoritative; layers baseline |
| New Go µ-service on internal platform, no docs | applies | gates on, fully used | applies, fully used | gates off | gates on, fully used | layers carry conventions from day one |
| Python repo on GitHub | applies | gates off (no go.mod) | applies | gates on | gates off | layer0 + git + GitHub, no Go leakage |
| GitHub OSS (Go) | applies | gates on | applies | gates on | gates off (emphatic) | layer0 + Go + git + GitHub, zero internal-platform leakage |

## Authoring rules for the layer files

- **Layer 0/1 must contain no repo-specific nouns** — no paths, branch names, service names.
  Layer 1 may name Go/git tools and idioms; a Layer 2 platform layer may name that platform's
  tools but keeps repo values as `<placeholders>`.
- **References are one-directional**: a repo may point at a layer; a layer must never point at
  a specific repo. A Layer 2 file may point at its Layer 1 baseline (`github.md` → `git.md`).
- **Never commit an internal/work platform layer file to a public repo** — keep it as a
  [private layer file](#private-layer-files-workinternal-layers).

## Maintenance discipline (the removal test)

These files should grow the same way any codebase should: additions earn their place, and nothing
sits there just because it seemed like a good idea once.

- **Add a rule only after it would have prevented an actual mistake** — not because it sounds
  reasonable in the abstract.
- **Remove a rule once it's being followed without being told** — a convention that's now just how
  things are done doesn't need to keep paying rent in every session's context.
- **Audit periodically for contradictions** across layer files and against a repo's own docs; two
  rules that disagree mean the model picks one arbitrarily.
- Longer files cost more context and weaken adherence — if a layer file is growing, look for what
  it's earned the right to keep before assuming it should just keep growing. If a file is growing
  because it's covering more than one topic, that's a signal to split it, the same way
  `philosophy.md` split into the four `layer0-universal/` files.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded `CLAUDE.md` and rules
file, so you can confirm the `layer0-universal/` files and the applicable Layer 1/2 files
actually loaded from `$CLAUDE_CONFIG_DIR/rules/`. Then ask the agent to confirm whether each
APPLY guard fired correctly for this repo, and whether local docs win on overlap. The decisive
negative test is a repo on none of the gated platforms/languages — only the `layer0-universal/`
files should apply.
