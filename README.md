# Dotfiles

## License

[WTFPL](COPYING)

## Philosophy & Stack

Battle-tested on macOS. Designed for both personal workstations and minimal server environments.

This configuration is built on three core principles:

1.  **Zero Home Presence (Strict XDG):** I am an absolutist about the [XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html). My `$HOME` is clean. With the exception of a single `.zshenv` entry point, every configuration, cache, and state file is forced into `~/.config`, `~/.cache`, or `~/.local/share` —even for tools like Homebrew, `wget`, and `less` that don't support it natively.

2.  **Modern Replacements:** Legacy Unix utilities are replaced with modern, faster (often Rust-based) alternatives.
    * `ls` → `eza` (with git status & icons)
    * `cat` → `bat` (syntax highlighting & git integration)
    * `find` → `fd`
    * `grep` → `ripgrep` (rg)
    * `cd` → `zoxide` (teleportation)

3.  **Explicit & Unified:**
    * **Theming:** A consistent **Catppuccin Mocha** theme is applied programmatically across Alacritty, Tmux, FZF, Bat, Delta, and Neovim.
    * **Workflow:** A "Tmux-First" approach where the terminal emulator (Alacritty) is merely a canvas. Window management, scrolling, and clipboard integration are handled explicitly by Tmux.
## Features

- **Fully Themed**: Consistent [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) theme across Alacritty, Tmux, FZF, Bat, Delta, and Neovim.
- Extensive Zsh [configuration](zsh/rc.d) and [plugins](zsh/plugins):
  - [powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt (Catppuccin styled)
  - [fzf-tab](https://github.com/Aloxaf/fzf-tab) for interactive, preview-enabled tab completion
  - [additional completions](https://github.com/zsh-users/zsh-completions)
  - [async autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [autopair](https://github.com/hlissner/zsh-autopair)
  - [zoxide](https://github.com/ajeetdsouza/zoxide) for smart directory jumping
- **Neovim**: Full [LazyVim](https://www.lazyvim.org/) IDE setup with Catppuccin theme.
- **Tmux**: Highly customized [configuration](tmux/tmux.conf) with:
  - Smart pane navigation (seamlessly switch between Vim and Tmux panes)
  - Minimal, info-rich status bar (CPU/RAM/Battery/Zoom indicators)
  - Popup scratchpad (`Prefix + g`)
  - Hybrid mouse workflow (Tmux for yanking, terminal for scrolling)
- **Alacritty**: Minimal, borderless [configuration](alacritty.toml) acting as a pure launchpad for Tmux.
- **Modern CLI Replacements**: `bat` (cat), `eza` (ls), `rg` (grep), `fd` (find), `delta` (diff), `doggo` (dig).

## Installation

Requirements:

- `zsh` 5.1 or newer (async stuff requires recent enough version of zsh)
- `git`

Dotfiles can be installed in any dir, but probably somewhere under `$HOME`.
Personally I use `$HOME/.local/dotfiles`.


[Deployment script](macos/deploy.zsh) is idempotent and handles:
1. Creating necessary XDG directory structures.
2. Installing Homebrew (interactive prompt for custom location) and all `Brewfile` packages.
3. Linking all config files to `$XDG_CONFIG_HOME`.
4. Compiling necessary terminfo and plugins (like `gitstatusd`).

## Configuration

### Zsh configuration

Keep in mind that Zsh configuration skips every global configuration file
except `/etc/zsh/zshenv`.

The difference is that `env.d` is sourced always while `rc.d` is sourced in interactive session only.

### Dependencies

The setup heavily relies on Homebrew to manage CLI tools. The `deploy.zsh` script handles the installation of:
- Core: `git`, `neovim`, `tmux`
- Shell: `zsh`, `coreutils`, `curl`
- Modern Utils: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`
- Data Tools: `jq`, `yq`