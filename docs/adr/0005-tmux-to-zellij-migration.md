# 5. tmux to Zellij migration

Date: 2026-07-05

## Status

Accepted

## Context

tmux was the login multiplexer, wired into `.zshrc` shell-start, with vendored
plugins (yank, catppuccin, cpu), a sesh session integration, and a
`generate_tmux_terminfo` step in `deploy.zsh` for the `tmux-256color` entry
(#2). The repo's stated stance is "Modern Replacements" and a "Zellij-First"
workflow — the terminal emulator is a canvas; window management, scrolling, and
clipboard integration live in Zellij (README philosophy). tmux carried config
weight the setup wanted to shed: a whole `tmux/` dir plus vendored plugins and a
separate terminfo entry (#2). Zellij runs under the outer `TERM`
(`xterm-ghostty`), so it needs no dedicated terminfo entry (#2 comment). It also
ships a native session manager, folding sesh's job back into the multiplexer
(#2, #55). The migration ran in two halves — add-alongside first, flip the
default only after a hands-on pass — because a full interactive Zellij session
couldn't be driven in the build sandbox, the same limitation the tmux/sesh
testing hit (#47).

## Decision

Replace tmux with Zellij as the login multiplexer. Zellij auto-starts on shell
login and always resurrects-or-creates a `default` session
(`zellij attach --create`); tmux, its vendored plugins, the sesh integration,
and the tmux terminfo generation are removed entirely (#54, #55).

## Alternatives considered

- **Stay on tmux** — cut against the repo's Zellij-First / Modern-Replacements
  stance and kept avoidable config weight: the `tmux/` dir, vendored plugins,
  and a dedicated `tmux-256color` terminfo step Zellij doesn't need since it
  inherits `xterm-ghostty` (#2, #2 comment, #54). No source names a concrete
  tmux capability Zellij couldn't match, so retention had no positive case here
  (inferred). Known cost of leaving: no `power-zoom`/tmux-fingers equivalent was
  found, and the z0rc mouse-selection fixes (#23) got no Zellij port — accepted
  as non-blocking, to be filed separately if they bite (#2).
- **Keep sesh for session management** — Zellij's native session manager plus
  the fzf-based `_zellij-sessions` picker cover the same job, so the separate
  sesh integration was dropped as dead (#2, #54).
- **Enable the kitty keyboard protocol under Zellij** — Neovim auto-requests it
  from any terminal that advertises support (Ghostty does), and with it on,
  Zellij's Ctrl-based mode-switch bindings silently stop firing while nvim is
  focused — the raw key reaches nvim instead (zellij-org/zellij#3723). Disabled
  in `config.kdl` (#55).

## Consequences

Simpler deploy: no `generate_tmux_terminfo` step, no `tmux/` dir or vendored
plugins, ~1545 lines removed (#54). Zellij runs under `xterm-ghostty` directly
(#2 comment). Vim-aware Ctrl-hjkl pane nav via vim-zellij-navigator forwards to
Neovim through smart-splits.nvim (#47); a zjstatus bar carries
session/tabs/mode/date (#55). Enforced now in `config.kdl` (kitty protocol off,
`pane_frames` off) and the `.zshrc` auto-start block. Gaps carried forward: no
`power-zoom`/tmux-fingers equivalent and no ported z0rc mouse-selection fixes
(#2, #23) — revisit if either becomes a real pain point. Revisit the
kitty-protocol decision if zellij-org/zellij#3723 is fixed upstream. The
`default`-session auto-start uses `attach --create` specifically because
`zellij --session` errors instead of resurrecting a dead session of that name
(#55).
