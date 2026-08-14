# Claude Code Agent Configuration

This repo **consumes** the shared, cross-repo Claude Code rules/agents/skills tree from the
`claude/global/` submodule ([`carpet-stain/agents`](https://github.com/carpet-stain/agents)) —
that repo's own [README](https://github.com/carpet-stain/agents/blob/main/README.md) is the
source of truth for why the tree is organized the way it is, the GATE/LOCAL-WINS/COMPOSE model,
and the skills/subagents it provides. This file covers only what's specific to consuming it
here: what stays local to this repo, and how deploy layers the two together.

Phase 1 of the extraction is dotfiles#567; `voice.md` and `backlog-manager.md` are Phase 2
(dotfiles#569) — see that issue for why they haven't moved yet.

## What stays local to this repo

A handful of files aren't part of the shared tree, either because they're specific to this
repo (`verify-nvim-config` checks _this_ repo's nvim config) or because they carry
repo-specific identity/memory that shouldn't be shared across every consumer of
`claude/global/` (`backlog-manager`'s MCP knowledge-graph memory, `voice.md`'s maintainer-voice
corpus):

| File                                | Why it stays local                                                      |
| ----------------------------------- | ----------------------------------------------------------------------- |
| `claude/rules/universal/voice.md`   | Seeded from this repo's own session transcripts (Phase 2, dotfiles#569) |
| `claude/agents/backlog-manager.md`  | Repo-specific MCP memory/identity (Phase 2, dotfiles#569)               |
| `claude/rules/platform/private/`    | Gitignored, machine-local platform files — never committed anywhere     |
| `claude/skills/verify-nvim-config/` | Verifies _this_ repo's nvim config specifically                         |

### Subagent memory: a private machine-global knowledge graph

Backlog-manager's memory is an MCP knowledge graph (`@modelcontextprotocol/server-memory`, wired
inline in its frontmatter) backed by one private local store at
`~/.claude/agent-memory-mcp/backlog-manager.jsonl` — ADR-0036 owns the decision and supersedes
the committed-file model (ADR-0027/0032/0033). Outside every repo, so private by construction;
writes persist immediately with no sync step or review gate. The dividing line from the
subagent's own definition (`claude/agents/backlog-manager.md`) is unchanged: a rule that would
hold for this subagent in _any_ repo belongs in the definition; a fact specific to one repo lives
in the graph, related to that repo's `repo-map` entity. Content follows the pointer-layer
contract (one-line pointer-shaped facts, never restated issue status); the `audit-memory` skill
(from `claude/global/`) is the detection backstop.

## Deployment (`~/.claude`, a documented XDG exception)

Claude Code defaults to `~/.claude`, which would normally violate this repo's Zero-Home-Presence
rule. This repo used to fight that by exporting `CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude` to
relocate it — but Claude Code's daemon, telemetry, and auth subsystems hardcode or fail to inherit
`CLAUDE_CONFIG_DIR` in spawned subprocesses (#134, upstream, as of 2.1.197), so the relocation only
ever half-worked: CLI config under `$XDG_CONFIG_HOME/claude`, daemon/telemetry state under
`~/.claude` regardless. `~/.claude` is now the accepted, documented home for everything — see
AGENTS.md's XDG-exceptions table.

The deploy scripts (`macos/deploy.zsh`, `linux/deploy.sh`) layer `claude/global/`'s shared tree
with this repo's local-only files into `~/.claude/{rules,agents,skills}`:

```text
claude/global/rules/{domain,tools}/  → ~/.claude/rules/{domain,tools}/   (whole-dir symlink — moved entirely)
claude/global/rules/universal/*.md   ┐
claude/rules/universal/voice.md      ┴→ ~/.claude/rules/universal/       (per-file symlinks — mixed source)
claude/global/rules/platform/github.md ┐
claude/rules/platform/private/         ┴→ ~/.claude/rules/platform/      (per-file symlinks — mixed source)
claude/global/agents/plan-reviewer.md  ┐
claude/agents/backlog-manager.md       ┴→ ~/.claude/agents/              (per-file symlinks — mixed source)
claude/global/skills/*/                ┐
claude/skills/verify-nvim-config/      ┴→ ~/.claude/skills/              (per-entry symlinks — mixed source)
claude/settings.json                   → ~/.claude/settings.json
```

`domain/` and `tools/` moved to `claude/global/` entirely (nothing local left in them), so a
single directory symlink still covers them — same zero-per-file-wiring property as before.
`universal/`, `platform/`, `agents/`, and `skills/` each mix a submodule majority with a named
local exception, so the destination is a real directory populated by one symlink per submodule
entry (globbed at deploy time — a new file landing in `claude/global/`'s tree needs no
deploy-script edit) plus the specific local files listed above.

`claude/settings.json` is unrelated to the rule files — it's Claude Code's own top-level config
(telemetry, error reporting, auto-update), kept here and symlinked so it's version-controlled
instead of a manual one-off edit.

> **Gitignore note:** the repo root has a `/CLAUDE.md` (a symlink to the dotfiles `AGENTS.md`, for
> the dotfiles repo's _own_ agent guidance) which is gitignored.

## Verifying it works

Run `/memory` in a fresh session inside any repo — it lists every loaded `CLAUDE.md` and rules
file, so you can confirm the `universal/` files (both the submodule's and `voice.md`) and the
applicable `tools/`/`platform/` files loaded from `~/.claude/rules/`. Then ask the agent whether
each file's GATE fired correctly and whether local docs win on overlap. For a precise trace of
which files loaded, when, and why, enable Claude Code's `InstructionsLoaded` hook, which logs
exactly that.
