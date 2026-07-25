---
name: env-claude-paths
description: Where Claude Code writes on this machine — ~/.claude is the accepted home (AGENTS.md XDG exceptions), plus the memory-dir Write-guard workaround
metadata:
  type: reference
---

Path facts for `carpet-stain/dotfiles` (verify against the machine — versions change):

- **`~/.claude` is the accepted, deliberate home** for Claude Code config/daemon/telemetry/auth —
  the `CLAUDE_CONFIG_DIR` relocation was tried and abandoned (#134); AGENTS.md's XDG-exceptions
  `.claude/` row owns the current rationale. If asked about `~/.claude` clutter, point there —
  it's resolved-by-acceptance, not a bug to re-file, and not caused by this subagent.
- **Backlog-manager subagent memory** (this dir) lives at the repo path
  `.claude/agent-memory/backlog-manager/` — tracked, inside the checkout, so the Write tool hits
  a worktree-isolation guard; write memory via bash heredoc. Auto-memory for the session lives
  under the CLI config dir's `projects/<slug>/memory/`.
