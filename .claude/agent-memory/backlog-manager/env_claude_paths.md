---
name: env-claude-paths
description: Where Claude Code writes on this machine, and the ~/.claude XDG leak (issue #134) — the daemon, not the subagent
metadata:
  type: reference
---

Path facts for `carpet-stain/dotfiles` (verify against the machine — versions change):

- `CLAUDE_CONFIG_DIR` = `$XDG_CONFIG_HOME/claude` (`~/.config/claude`), exported in `zsh/.zshenv:71`.
  Main CLI config, `projects/`, and the primary `daemon/` correctly go here.
- **Backlog-manager subagent memory** (this dir) lives at the repo path
  `.claude/agent-memory/backlog-manager/` — tracked, inside the checkout, so the Write tool hits
  a worktree-isolation guard; write memory via bash heredoc. Auto-memory (`MEMORY.md` index for
  the session) lives at `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/`.
- **`~/.claude` leak = issue #134.** Claude Code's daemon/telemetry/auth subsystems write
  `~/.claude/{daemon/auth, daemon-auth-status.json, daemon-auth-cooldown, telemetry/}` even with
  `CLAUDE_CONFIG_DIR` set — upstream bug (binary builds `homedir()+".claude"`; daemon is a spawned
  subprocess that may not inherit the var; v2.1.197 Homebrew cask). **Not** caused by the dotfiles
  config or the subagent. If asked about `~/.claude` clutter again, it's #134, don't re-suspect
  the subagent.
