# AGENTS.md

Guidance for AI assistants working in this repo. Vendor-neutral; `CLAUDE.md` is a
symlink to this file.

## What this is

Personal macOS dotfiles: Ghostty + Zellij + zsh + Neovim, themed Catppuccin
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
- `theme/` — Catppuccin submodules per tool (bat, delta, zsh-fsh). Ghostty uses
  its built-in `catppuccin-mocha` theme, no submodule.
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

Follow `git/committemplate` and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Every commit:

1. **Subject**: `type(scope): description`
   - `type` ∈ feat, fix, docs, style, refactor, perf, test, build, ci, chore
   - `scope` (optional): repo area — zsh, zellij, git, nvim, macos, theme
   - `description`: imperative, lowercase, no trailing period; keep the whole
     line ≤50 chars where possible (hard limit 72)
   - Breaking change: `type!:` or a `BREAKING CHANGE:` footer
   - Good: `fix(zsh): bind arrow keys via terminfo`
   - Bad: `fixed arrow keys` (no type, past tense, vague)
2. **Blank line** between subject and body.
3. **Body** (wrap at 72 chars): explain *what* and *why*, never *how* — the diff
   shows how. Omit only for trivial, self-evident changes.
4. **Trailers** (optional): add a `Co-authored-by: Name <email>` line for each
   human contributor, one blank line before the footer block. Do not add AI or
   assistant attribution.

Scope each commit to one logical change — prefer several focused commits over one
sweeping commit. Propose the split and messages before committing.

## Git workflow

Branching model: **long-lived `dev` + protected `main`**, squash-merged.

1. All work happens on `dev` — commit freely and messily; WIP commits don't need
   to follow the commit style (they get squashed away).
2. **Scope each PR to one logical change.** Under squash-merge one PR becomes one
   commit on `main`, so a focused PR yields a clean, atomic, revertable commit.
   Never bundle unrelated changes into a single PR just to save a round trip.
3. When a change is ready and tested, open a PR `dev` → `main`. CI must pass, then
   **squash-merge**. The PR title becomes the `main` commit message, so title the
   PR as a Conventional Commit (`type(scope): subject`).
4. After the merge, reset `dev` onto `main` so histories don't drift:
   `git switch dev && git reset --hard origin/main && git push --force-with-lease origin dev`
5. `main` stays releasable. To cut `vX.Y.Z` ([SemVer](https://semver.org)),
   git-cliff builds `CHANGELOG.md` from the Conventional Commits:
   - On `dev`: `git cliff --tag vX.Y.Z -o CHANGELOG.md`, commit as
     `chore(release): vX.Y.Z`, PR, squash-merge.
   - Tag it: `git tag -a vX.Y.Z -m vX.Y.Z && git push origin vX.Y.Z`.
   - Publish notes from the same source:
     `gh release create vX.Y.Z --notes-file <(git cliff --tag vX.Y.Z --latest --strip all)`.

`main` is never committed to directly (except one-time bootstraps). Merge method
is **squash only**; rebase-merge stays disabled and is a deliberate, temporary
exception used only to land a series of already-clean commits atomically.
