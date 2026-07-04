# AGENTS.md

Guidance for AI assistants working in this repo. Vendor-neutral; `CLAUDE.md` is a
symlink to this file.

## What this is

Personal macOS dotfiles: Alacritty + tmux + zsh + Neovim, themed Catppuccin
Mocha throughout, XDG-compliant. Primary target is macOS on Apple Silicon.

## Philosophy

- **Best tool for the job.** Prefer purpose-built modern tools (fd, rg, eza, bat,
  delta, zoxide, fzf) over defaults.
- **Homebrew-first.** Install packages via Homebrew. Only when Homebrew lacks a
  package does it become a git submodule. No dotfile manager or framework —
  Powerlevel10k is the sole exception.
- **XDG discipline.** Keep `$HOME` clean: only `.zshenv` lives there, everything
  else goes under `$XDG_{CONFIG,CACHE,DATA,STATE}_HOME`. Respect the distinction —
  config vs cache vs data vs state.
- **No bloat.** Every setting earns its place. Delete dead config; don't
  accumulate.
- **Readability over cleverness.** Explicit names, conventional idioms, comments
  only where intent is non-obvious (never restate what the code plainly says).
- **Portable, extendable, quick to install.** A fresh machine should reach a
  working setup by cloning and running the deploy script.

## Structure & conventions

- `zsh/.zshenv` — sourced on every shell: env vars, PATH, tool config. No output,
  no tty assumptions.
- `zsh/.zshrc` — interactive only. Acts as a table of contents that sources
  `rc.d/` modules in dependency order.
- `zsh/rc.d/` — one concern per file (options, widgets, keybindings, aliases,
  completions, fzf-tab, powerlevel10k).
- `zsh/env.d/` — sourced always (e.g. `ls_colors.zsh`).
- `zsh/fpath/` — custom zle widgets and completions, autoloaded.
- `theme/` — Catppuccin submodules per tool (alacritty, bat, delta, zsh-fsh).
- `macos/deploy.zsh` — single bootstrap: creates XDG dirs, symlinks configs,
  installs Homebrew + Brewfile, syncs submodules, builds caches/terminfo.
- Section headers use the ASCII box style: `# +------+`.
- Keep ordering dependencies explicit and commented (e.g. "must come after
  compinit").

## When editing

- Read a file (and anything it depends on) before changing it.
- When a change spans files, update all of them (e.g. moving a path in `.zshenv`
  means updating `deploy.zsh`). Reconcile, don't leave drift.
- Fix bugs found along the way, but call them out.
- Summarize what changed and why — a short table beats prose.
- Prefer the change that removes a setting over the one that adds one.

## Commit style

Follow `git/committemplate`. Every commit:

1. **Subject**: imperative mood, capitalized, no trailing period, ≤50 chars.
   - Good: `Bind arrow keys via terminfo`
   - Bad: `fixed arrow keys` (past tense, lowercase, vague)
2. **Blank line** between subject and body.
3. **Body** (wrap at 72 chars): explain *what* and *why*, never *how* — the diff
   shows how. Omit only for trivial, self-evident changes.
4. **Trailers**: end with the Claude `Co-Authored-By` line, one blank line before
   it. Add `Co-authored-by:` lines for human contributors above it.

Scope each commit to one logical change — prefer several focused commits over one
sweeping commit. Propose the split and messages before committing.
