# Dotfiles

<!--toc:start-->

- [Dotfiles](#dotfiles)
  - [License](#license)
  - [Philosophy & Stack](#philosophy--stack)
  - [Features](#features)
  - [Installation](#installation)
  - [Releases](#releases)
  - [Configuration](#configuration)
    - [Zsh configuration](#zsh-configuration)
    - [Keybindings](#keybindings)
    - [Dependencies](#dependencies)

<!--toc:end-->

## License

[WTFPL](COPYING)

## Philosophy & Stack

Battle-tested on macOS. Designed for both personal workstations and minimal
server environments.

This configuration is built on five core principles:

1. **Zero Home Presence (Strict XDG):** Every configuration, cache, and state
   file lives under `~/.config`, `~/.cache`, or `~/.local/share` — even for
   tools like Homebrew, `wget`, and `less` that don't support it natively. Only
   `.zshenv` lives in `$HOME` (zsh's fixed entry point). See the
   [XDG Base Directory Specification][xdg-spec]; documented exceptions live in
   [AGENTS.md](AGENTS.md#xdg-exceptions).

2. **Modern Replacements:** Legacy Unix utilities are replaced with modern,
   faster (often Rust-based) alternatives.
   - `ls` → `eza` (with git status & icons)
   - `cat` → `bat` (syntax highlighting & git integration)
   - `find` → `fd`
   - `grep` → `ripgrep` (rg)
   - `cd` → `zoxide` (teleportation)

3. **Explicit & Unified:**
   - **Theming:** A consistent [Catppuccin Mocha][catppuccin] theme applied
     programmatically across Ghostty, Zellij, FZF, Bat, Delta, and Neovim.
   - **Workflow:** A "Zellij-First" approach where the terminal emulator
     (Ghostty) is merely a canvas. Window management, scrolling, and clipboard
     integration are handled explicitly by Zellij.

4. **Homebrew-first:** Packages install via Homebrew; only when Homebrew
   lacks one does it become a git submodule (Powerlevel10k is the sole
   exception). Linux has no Homebrew — `linux/deploy.sh` uses `apt` where
   possible and falls back to git-cloning zsh plugins directly.

5. **Portable, quick to install:** A fresh machine reaches a working setup by
   cloning this repo and running the deploy script — see Installation below.

[xdg-spec]: http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
[catppuccin]: https://github.com/catppuccin/catppuccin

## Features

- **Fully Themed**: Consistent Catppuccin Mocha theme across Ghostty, Zellij,
  FZF, Bat, Delta, and Neovim.
- Extensive Zsh [configuration](zsh/rc.d) and [plugins](zsh/plugins):
  - [powerlevel10k][p10k] prompt (Catppuccin styled)
  - [fzf-tab][fzf-tab] for interactive, preview-enabled tab completion
  - [additional completions][zsh-completions]
  - [async autosuggestions][zsh-autosuggestions]
  - [fast-syntax-highlighting][fsh]
  - [autopair][autopair]
  - [zoxide][zoxide] for smart directory jumping
- **Neovim**: Full [LazyVim](https://www.lazyvim.org/) IDE setup with
  Catppuccin theme, Zellij-aware pane navigation via
  [smart-splits.nvim][smart-splits], and LSP/formatting/linting for
  Python, Go, Bash, JSON, YAML, and Markdown.
- **Zellij**: Customized [configuration](zellij/config.kdl) with:
  - Vim-aware pane navigation via [vim-zellij-navigator][vzn]
    (switch between Neovim splits and Zellij panes with the same keys)
  - Catppuccin Mocha status bar via [zjstatus][zjstatus] (session, tabs, time)
  - Prefix-less tab switching (`Alt-,`/`Alt-.`)
- **Ghostty**: Minimal, borderless [configuration](ghostty/config) acting as a
  pure launchpad for Zellij.
- **Modern CLI Replacements**: `bat` (cat), `eza` (ls), `rg` (grep), `fd`
  (find), `delta` (diff), `doggo` (dig).

[p10k]: https://github.com/romkatv/powerlevel10k
[fzf-tab]: https://github.com/Aloxaf/fzf-tab
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[fsh]: https://github.com/zdharma-continuum/fast-syntax-highlighting
[autopair]: https://github.com/hlissner/zsh-autopair
[zoxide]: https://github.com/ajeetdsouza/zoxide
[smart-splits]: https://github.com/mrjones2014/smart-splits.nvim
[vzn]: https://github.com/hiasr/vim-zellij-navigator
[zjstatus]: https://github.com/dj95/zjstatus

## Installation

Requirements: `zsh` 5.1 or newer, and `git`.

### macOS (primary target — Apple Silicon)

Clone the repo to `~/.config/dotfiles` and run the deploy script:

```zsh
git clone https://github.com/carpet-stain/dotfiles ~/.config/dotfiles
zsh ~/.config/dotfiles/macos/deploy.zsh
```

The [deploy script](macos/deploy.zsh) is idempotent and handles:

1. Creating necessary XDG directory structures.
2. Installing Homebrew and all `Brewfile` packages.
3. Linking all config files to `$XDG_CONFIG_HOME`.
4. Compiling terminfo entries and shell plugins.

### Linux (Debian — secondary target)

Debian support ([`linux/deploy.sh`](linux/deploy.sh)) is a secondary target,
mainly for a Linux dev VM you SSH into — e.g. a remote work box. It sets up
the shell/CLI environment only; GUI concerns don't apply. Run as a regular
user with passwordless sudo:

```bash
git clone https://github.com/carpet-stain/dotfiles ~/.config/dotfiles
bash ~/.config/dotfiles/linux/deploy.sh
```

Same shape as the macOS deploy, but uses `apt` ([`linux/Aptfile`](linux/Aptfile))
plus GitHub-release binaries for tools too old or missing in Debian's repos,
and vendored submodules for the zsh plugins. If you SSH in from a Ghostty
client, it also compiles the `xterm-ghostty` terminfo that Debian lacks.

## Releases

Tagged releases (`vX.Y.Z`) mark known-good checkpoints — see
[CHANGELOG.md](CHANGELOG.md) for what changed in each. Useful for rolling
back after something breaks, or for setting up a new machine on a specific
version rather than whatever `main` happens to be. (Cutting a new release is
covered in [AGENTS.md](AGENTS.md#git-workflow) — this section is about
consuming one.)

**Roll back an existing clone:**

```zsh
git -C ~/.config/dotfiles fetch --tags
git -C ~/.config/dotfiles checkout v1.3.0
```

Symlinked configs update immediately — they point into the checked-out
working tree. Re-run the deploy script too if the rollback involves a
tool/package change, not just config content.

**Clone fresh at a specific release:**

```zsh
git clone https://github.com/carpet-stain/dotfiles ~/.config/dotfiles
git -C ~/.config/dotfiles checkout v1.3.0
zsh ~/.config/dotfiles/macos/deploy.zsh
```

Both leave the repo in a detached HEAD state — switch back with
`git checkout main` when you're done (or `dev`, if you're continuing to
develop).

## Configuration

### Zsh configuration

Zsh configuration skips every global configuration file except
`/etc/zsh/zshenv`. See [AGENTS.md](AGENTS.md#structure--conventions) for how
`env.d/` and `rc.d/` are organized and sourced.

### Keybindings

[KEYBINDINGS.md](KEYBINDINGS.md) documents the full Ghostty → Zellij → Neovim keystroke chain —
which layer owns which key, and the conflicts found (and fixed) between them. Read it before
adding a new `Ctrl`/`Alt`/`Cmd` binding anywhere in that chain.

### Dependencies

The setup relies on Homebrew to manage CLI tools. The `deploy.zsh` script
handles the installation of:

- Core: `git`, `neovim`, `zellij`
- Shell: `zsh`, `coreutils`, `curl`
- Modern Utils: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`
- Data Tools: `jaq` (fast `jq` alternative)
- Language Toolchains: `go`, `node`, `python` — needed for Neovim's LSP
  tooling (`gopls`, `pyright`/`ruff`, `bash-language-server`), not just
  their own development

## Development

Repo dev tasks — lint, the Linux VM e2e test, local CI via `act`, changelog
preview — run through [`just`](https://just.systems). Run `just --list` for the
full set.
