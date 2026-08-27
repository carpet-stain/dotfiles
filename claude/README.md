# Claude Code Agent Configuration

This repo **consumes** the shared, cross-repo Claude Code rules/agents/skills tree from the
`claude/global/` submodule ([`carpet-stain/agents`](https://github.com/carpet-stain/agents)) —
that repo's own [README](https://github.com/carpet-stain/agents/blob/main/README.md) is the
source of truth for why the tree is organized the way it is, the GATE/LOCAL-WINS/COMPOSE model,
and the skills/subagents it provides. This file covers only what's specific to consuming it
here: what stays local to this repo, and how deploy layers the two together.

The extraction landed in two phases: dotfiles#567 moved the stable subset and proved the
submodule + deploy mechanics; dotfiles#569 moved the two files held back for their churn
(`backlog-manager.md`, `voice.md`) once their in-flight PRs settled. Both are done — everything
that can live in `claude/global/` now does.

## Where new agent-config work happens

New rules, skills, personas, or behavior changes are issues/PRs against
[`carpet-stain/agents`](https://github.com/carpet-stain/agents), not here — this repo only
consumes that tree (deploy symlinks) plus the two named local exceptions below
(`carpet-stain/agents#96`).

## What stays local to this repo

Two things aren't part of the shared tree, both specific to this repo rather than to how Claude
Code agents work in general:

| File                                | Why it stays local                                                  |
| ----------------------------------- | ------------------------------------------------------------------- |
| `claude/rules/platform/private/`    | Gitignored, machine-local platform files — never committed anywhere |
| `claude/skills/verify-nvim-config/` | Verifies _this_ repo's nvim config specifically                     |

`backlog-manager`'s private memory store (`~/.claude/agent-memory-mcp/backlog-manager.jsonl`) is
machine-global, not repo-local — it's documented in `claude/global/`'s own README alongside the
subagent definition now that both live there.

## Deployment (`~/.claude`, a documented XDG exception)

Claude Code defaults to `~/.claude`, which would normally violate this repo's Zero-Home-Presence
rule. This repo used to fight that by exporting `CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude` to
relocate it — but Claude Code's daemon, telemetry, and auth subsystems hardcode or fail to inherit
`CLAUDE_CONFIG_DIR` in spawned subprocesses (#134, upstream, as of 2.1.197), so the relocation only
ever half-worked: CLI config under `$XDG_CONFIG_HOME/claude`, daemon/telemetry state under
`~/.claude` regardless. `~/.claude` is now the accepted, documented home for everything — see
AGENTS.md's XDG-exceptions table.

The deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) layer `claude/global/`'s shared tree
with this repo's two remaining local-only files into `~/.claude/{rules,agents,skills}`:

```text
claude/global/rules/{domain,tools,universal}/ → ~/.claude/rules/{domain,tools,universal}/ (whole-dir symlink — moved entirely)
claude/global/agents/                          → ~/.claude/agents/                        (whole-dir symlink — moved entirely)
claude/global/rules/platform/github.md ┐
claude/rules/platform/private/         ┴→ ~/.claude/rules/platform/      (per-file symlinks — mixed source)
claude/global/skills/*/                ┐
claude/skills/verify-nvim-config/      ┴→ ~/.claude/skills/              (per-entry symlinks — mixed source)
claude/settings.json                   → ~/.claude/settings.json
```

`domain/`, `tools/`, `universal/`, and `agents/` all moved to `claude/global/` entirely (nothing
local left in any of them after dotfiles#569), so a single directory symlink covers each —
zero-per-file-wiring. `platform/` and `skills/` still mix a submodule majority with a named
local exception (a gitignored `private/`; `verify-nvim-config`), so those destinations stay real
directories populated by one symlink per submodule entry (globbed at deploy time — a new file
landing in `claude/global/`'s tree needs no deploy-script edit) plus the named local file.

`claude/settings.json` is unrelated to the rule files — it's Claude Code's own top-level config
(telemetry, error reporting, auto-update), kept here and symlinked so it's version-controlled
instead of a manual one-off edit.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`, for
> the dotfiles repo's _own_ agent guidance) which is gitignored.

## Cloud channel (repo-root `.claude/`, distinct from this `claude/` tree)

A claude.ai/code cloud session (web, iOS) only ever reads a checked-out repo's own
`.claude/agents/*.md` — never `~/.claude/`, so the submodule/symlink deployment above doesn't
reach it. `.claude/agents/`, `.claude/skills/`, and `.claude/.agents-ref` at the repo root are a
second, additive channel: a pinned, vendored copy synced from `carpet-stain/agents` by
`agents-sync.yml` and enforced against drift by `agents-drift-guard.yml` (`carpet-stain/dotfiles`
ADR-0039 amend-marker; `carpet-stain/agents` ADR-0002 records the channel).

Because this machine is both source and consumer, its deployed `~/.claude/agents` symlink
(this `claude/` tree's submodule head, pull-latest) and the committed `.claude/agents` vendored
copy (pinned to a lagging SHA) are **two load paths that can legitimately disagree** — that's the
pin lag, not drift. Edit `claude/global/` (the submodule) to change agent behavior; the vendored
`.claude/` copy is cloud-only and inert locally, updated by `agents-sync.yml`, never by hand.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded `CLAUDE.md` and rules
file, so you can confirm the `universal/` files and the applicable `tools/`/`platform/` files
loaded from `~/.claude/rules/`. Then ask the agent whether
each file's GATE fired correctly and whether local docs win on overlap. For a precise trace of
which files loaded, when, and why, enable Claude Code's `InstructionsLoaded` hook, which logs
exactly that.
