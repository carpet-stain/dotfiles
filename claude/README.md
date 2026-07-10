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

| Layer | File | Scope | Loading |
|-------|------|-------|---------|
| **0 — Philosophy** | `rules/philosophy.md` | Universal, language/platform-agnostic | Always applies |
| **1 — Go** | `rules/go.md` | Go repos only | Self-gates on `go.mod` |
| **2 — GitHub** | `rules/github.md` | GitHub-hosted repos only | Self-gates on github.com origin |
| **2 — Platform (private)** | *(machine-local, gitignored)* | Repos on a given hosting platform | Self-gates on that platform's tooling |
| **3 — Repo** | *(in each repo)* `AGENTS.md` + `docs/` | One repo only | Repo's own files |

There is no loader file. `claude/rules/*.md` deploy straight into Claude Code's own
`$CLAUDE_CONFIG_DIR/rules/` directory — a first-class, user-level mechanism it already
auto-discovers and loads, unconditionally, in every project. Dropping a layer file in gets
it loaded; there's nothing to wire.

Platform layers for **private or work-internal** hosting environments are deliberately
**not committed** here — see [Private layer files](#private-layer-files-workinternal-layers) below.

## The model: load-all, then self-gate ("blacklist")

Every layer file sits in `$CLAUDE_CONFIG_DIR/rules/` and loads in **every** project. Scope is
enforced *after* loading, by an **APPLY guard** at the top of each file that the agent evaluates
against the current repo:

- `philosophy.md` → applies always (no gate).
- `go.md` → applies only if `go.mod` exists at the repo root; otherwise ignored.
- `github.md` → applies only if the repo's origin is GitHub; otherwise ignored.
- a private platform layer → applies only if that platform's tooling is present; otherwise
  ignored (emphatically — its commands are *wrong*, not merely unnecessary, elsewhere).
  Distinct hosting platforms are mutually exclusive per repo — each gates on its own tooling.

This is a **blacklist** model (load everything, exclude what doesn't fit) rather than a
whitelist (opt-in per repo). Chosen because there are only a few, broad layer files that match
most of my work, so the always-loaded token cost is negligible and there is **zero per-repo
wiring** in the common case. If many niche layers accumulate later, revisit — whitelist
scales better then.

### Trade-off (be honest)

The gating is **soft**: it works because the model honors the guard text, not because the
layer is structurally absent. Reliability is high for crisp guards ("no `go.mod` → ignore").
Every repo pays the token cost of all layers even when gated off.

## Local-wins precedence

When an applied layer overlaps a repo's own docs, **the repo wins**. This is enforced
redundantly so no single soft instruction is load-bearing:

1. Each layer file's APPLY guard says "if the repo has its own doc, prefer it; treat this as baseline."
2. The repo's committed `AGENTS.md` independently claims authority for its `docs/`.
3. (For composed repos) the COMPOSE step below writes that precedence line into the repo.

Philosophy (Layer 0) is the exception: a repo never *overrides* it — a repo's `DESIGN.md`
*illustrates* how the principles are realized there. Illustrate, don't replace.

## COMPOSE protocol (Layers 1 & 2 only)

Layers 1 and 2 are **templates**. `go.md` has abstractions ("your linter"); a platform layer
has literal `<placeholders>` (repo id, branch names). When a repo *lacks* a concrete doc for
that layer, the file's COMPOSE protocol tells the agent how to distill a repo-specific doc
(e.g. `docs/CODING.md`, `docs/OPERATIONS.md`) by filling in the real nouns, then wire the
precedence line. Default is **propose-don't-create** — the agent suggests and waits before
writing committed files.

For a *mature* repo that already has those docs, COMPOSE is **inert**: the layer file was
distilled *from* that repo and must not be fed back. Only the APPLY guards fire, deferring to
the existing local docs.

Layer 0 has **no** COMPOSE protocol — a standard is applied, not instantiated.

## Deployment (Strict XDG)

Claude Code defaults to `~/.claude`, which violates this repo's Zero-Home-Presence rule.
Instead, `zsh/.zshenv` exports:

```sh
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
```

and the deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) symlink **every layer file
present** straight into `$XDG_CONFIG_HOME/claude/rules/`:

```
claude/rules/*.md            → $XDG_CONFIG_HOME/claude/rules/*.md
```

The scripts glob `rules/*.md` rather than naming each file, so machine-private layer files
(gitignored, see below) are linked too without editing the tracked scripts. Claude Code reads
`$CLAUDE_CONFIG_DIR/rules/` itself — every `*.md` there loads at launch with no index file, no
import list, and nothing to keep in sync when a file is added, renamed, or removed. Edit a
source file here → the symlink reflects it → every project inherits the change, with nothing
copied.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`,
> for the dotfiles repo's *own* agent guidance) which is gitignored.

## Private layer files (work/internal layers)

Some platform layers describe **internal or employer-owned tooling** (hostnames, CLIs, build
systems) that must **never** land in this public repo. They are kept **machine-local and
gitignored**, yet still load through the same mechanism as everything else here — there's no
separate private-only wiring to maintain. The setup:

1. **Write the layer file** at `claude/rules/<name>.md` with its own APPLY guard, exactly like
   a committed layer. Gitignore it in `.gitignore`:
   ```gitignore
   claude/rules/<name>.md
   ```
2. **Deploy.** The scripts glob every `rules/*.md`, so the private file is symlinked into
   `$CLAUDE_CONFIG_DIR/rules/` alongside the public ones, and Claude Code auto-discovers it —
   nothing else to wire.

**On a fresh clone** (or any machine that lacks the file) it's simply absent from
`claude/rules/`, so the glob finds nothing to symlink for it — the public layers load normally
with zero internal leakage. On a machine that needs it, drop the gitignored file in place and
re-deploy.

This keeps the public repo clean while letting a work laptop reuse the same dotfiles with its
internal platform layer fully wired.

## How it behaves per repo (worked examples)

| Repo | philosophy | go | private platform | Net effect |
|------|-----------|----|------------------|-----------|
| Go + internal platform, rich docs | applies; DESIGN.md shows how | gates on, but CODING.md wins | gates on, but OPERATIONS.md wins | local docs authoritative; layers baseline |
| New Go µ-service on internal platform, no docs | applies | gates on, fully used | gates on, fully used | layers carry conventions from day one |
| Python repo | applies | gates off (no go.mod) | gates off | philosophy only — no wrong context |
| GitHub OSS (Go) | applies | gates on | gates off (emphatic) | philosophy + Go, zero internal-platform leakage |

## Authoring rules for the layer files

- **Layer 0/1 must contain no repo-specific nouns** — no paths, branch names, service names.
  Layer 1 may name Go tools/idioms; a Layer 2 platform layer may name that platform's tools
  but keeps repo values as `<placeholders>`.
- **References are one-directional**: a repo may point at a layer; a layer must never point at
  a specific repo.
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
  it's earned the right to keep before assuming it should just keep growing.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded `CLAUDE.md` and rules
file, so you can confirm `philosophy.md` and the applicable layers actually loaded from
`$CLAUDE_CONFIG_DIR/rules/`. Then ask the agent to confirm whether each APPLY guard fired
correctly for this repo, and whether local docs win on overlap. The decisive negative test is a
repo on none of the gated platforms/languages — only `philosophy` should apply.
