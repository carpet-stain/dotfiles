#!/usr/bin/env bash
# Deploy dotfiles on Debian 12 (Bookworm).
# Run as a regular user with passwordless sudo (the default on OrbStack VMs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="$HOME/.local/bin"

ARCH="$(uname -m)"   # x86_64 or aarch64
# shellcheck disable=SC1091 # /etc/os-release is a system file, not part of this repo
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"   # e.g. bookworm, bullseye

# Guarantee $LOCAL_BIN (where this script installs neovim, delta, zellij,
# eza) and the standard system dirs are searched, regardless of what PATH
# looks like in the calling environment — a non-login or minimal shell may
# not have either, which otherwise surfaces as a confusing "command not
# found" from a later step for a binary this same run just installed.
export PATH="$LOCAL_BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# +---------+
# | RUNNERS |
# +---------+

required() {
  local desc="$1"; shift
  printf '%s...\n' "$desc"
  local output
  if output=$("$@" 2>&1); then
    printf '  ...done\n'
  else
    printf '  FAILED:\n%s\n' "$output"
    exit 1
  fi
}

optional() {
  local desc="$1"; shift
  printf '%s...\n' "$desc"
  local output
  if output=$("$@" 2>&1); then
    printf '  ...done\n'
  else
    printf '  FAILED (continuing):\n%s\n' "$output"
  fi
}

# Returns the first download URL from a GitHub release matching a pattern.
gh_latest_url() {
  curl -sf "https://api.github.com/repos/$1/releases/latest" \
    | grep -oP '"browser_download_url":\s*"\K[^"]+' \
    | grep "$2" \
    | head -1
}

# +----------------+
# | XDG DIRS       |
# +----------------+

create_directories() {
  mkdir -p \
    "$XDG_CONFIG_HOME/bat/themes" \
    "$XDG_CONFIG_HOME/direnv" \
    "$XDG_CONFIG_HOME/eza" \
    "$XDG_CONFIG_HOME/fsh" \
    "$XDG_CONFIG_HOME/git" \
    "$XDG_CONFIG_HOME/htop" \
    "$XDG_CONFIG_HOME/nvim" \
    "$XDG_CONFIG_HOME/ripgrep" \
    "$XDG_CONFIG_HOME/tealdeer" \
    "$XDG_CONFIG_HOME/zellij/themes" \
    "$XDG_CONFIG_HOME/zellij/layouts" \
    "$XDG_CACHE_HOME/bat" \
    "$XDG_CACHE_HOME/direnv" \
    "$XDG_CACHE_HOME/fast-syntax-highlighting" \
    "$XDG_CACHE_HOME/nvim" \
    "$XDG_CACHE_HOME/tealdeer" \
    "$XDG_CACHE_HOME/zsh/completions" \
    "$XDG_DATA_HOME/direnv" \
    "$XDG_DATA_HOME/go" \
    "$XDG_DATA_HOME/nvim" \
    "$XDG_DATA_HOME/terminfo" \
    "$XDG_DATA_HOME/zoxide" \
    "$XDG_DATA_HOME/zsh/plugins" \
    "$XDG_STATE_HOME/less" \
    "$XDG_STATE_HOME/zsh" \
    "$LOCAL_BIN"
  mkdir -p "$XDG_CONFIG_HOME/ssh" && chmod 700 "$XDG_CONFIG_HOME/ssh"
}

# +---------+
# | APT     |
# +---------+

bootstrap_apt() {
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends curl wget gpg ca-certificates
}

add_apt_repos() {
  # GitHub CLI
  if ! dpkg -l gh &>/dev/null 2>&1; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    printf 'deb [arch=%s signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
      "$(dpkg --print-architecture)" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  fi

  # NodeSource — Node 20 LTS
  if ! node --version 2>/dev/null | grep -q '^v20'; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null
  fi

  # Debian backports — golang-go 1.22+ (stable's own golang-go is too old for
  # gopls on both Bookworm and Bullseye). Hardcoding "bookworm-backports"
  # here would silently glue a wrong-release apt source onto any other
  # Debian version, which can leave dpkg/apt in a broken, hard-to-diagnose
  # state — always derive the suite name from the running release instead.
  if ! grep -rq "${CODENAME}-backports" /etc/apt/sources.list* 2>/dev/null; then
    printf 'deb http://deb.debian.org/debian %s-backports main\n' "$CODENAME" \
      | sudo tee /etc/apt/sources.list.d/backports.list > /dev/null
  fi

  sudo apt-get update -qq
}

install_apt_packages() {
  # One transaction for everything, Aptfile packages plus golang-go (pinned
  # to backports via the pkg/release syntax), gh, and nodejs. Three separate
  # apt-get install calls here previously let a later transaction silently
  # remove a package an earlier one had just installed (observed: zsh and
  # tealdeer vanished after gh/nodejs resolved) with no visible failure —
  # resolving the whole dependency graph at once means apt either satisfies
  # everything or reports the conflict loudly instead of quietly dropping it.
  local packages
  packages=$(grep -v '^\s*#' "$SCRIPT_DIR/Aptfile" | grep -v '^\s*$' | tr '\n' ' ')
  # golang-go/<release> only pins that one package to backports — unlike
  # `-t <release>` (which sets the preference for the whole resolution), the
  # pkg/release suffix doesn't extend to golang-go's own deps, so its
  # backports golang-src requirement has to be pinned the same way too.
  # shellcheck disable=SC2086
  sudo apt-get install -y --no-install-recommends \
    $packages "golang-go/${CODENAME}-backports" "golang-src/${CODENAME}-backports" gh nodejs
}

# +-------------------+
# | GITHUB BINARIES   |
# +-------------------+
# Tools not packaged in Debian 12: neovim (0.7.2 is too old), git-delta,
# zellij, eza. Install pre-built release binaries from GitHub.

install_neovim() {
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="x86_64" ;;
    aarch64) asset_arch="arm64"  ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac

  local url; url="$(gh_latest_url neovim/neovim "nvim-linux-${asset_arch}.tar.gz")"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  local src; src="$(find "$tmp" -maxdepth 1 -name 'nvim-linux-*' -type d | head -1)"

  cp "$src/bin/nvim" "$LOCAL_BIN/nvim"
  chmod +x "$LOCAL_BIN/nvim"
  # Runtime must sit at $HOME/.local/share/nvim/runtime relative to the binary
  cp -r "$src/share/nvim" "$XDG_DATA_HOME/"
  [[ -d "$src/lib" ]] && { mkdir -p "$HOME/.local/lib"; cp -r "$src/lib/." "$HOME/.local/lib/"; }
  rm -rf "$tmp"
}

install_git_delta() {
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="x86_64-unknown-linux-musl"   ;;
    aarch64) asset_arch="aarch64-unknown-linux-gnu"   ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac

  local url; url="$(gh_latest_url dandavison/delta "delta-.*-${asset_arch}.tar.gz")"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  find "$tmp" -name 'delta' -type f -exec cp {} "$LOCAL_BIN/delta" \;
  chmod +x "$LOCAL_BIN/delta"
  rm -rf "$tmp"
}

install_zellij() {
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="x86_64-unknown-linux-musl"  ;;
    aarch64) asset_arch="aarch64-unknown-linux-musl" ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac

  local url; url="$(gh_latest_url zellij-org/zellij "zellij-${asset_arch}.tar.gz")"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  cp "$tmp/zellij" "$LOCAL_BIN/zellij"
  chmod +x "$LOCAL_BIN/zellij"
  rm -rf "$tmp"
}

install_eza() {
  local asset_arch
  case "$ARCH" in
    # eza only publishes a musl build for x86_64; aarch64 is gnu-only.
    x86_64)  asset_arch="x86_64-unknown-linux-musl" ;;
    aarch64) asset_arch="aarch64-unknown-linux-gnu" ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac

  local url; url="$(gh_latest_url eza-community/eza "eza_${asset_arch}.tar.gz")"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  cp "$tmp/eza" "$LOCAL_BIN/eza"
  chmod +x "$LOCAL_BIN/eza"
  rm -rf "$tmp"
}

# Shared installer for the tools below: none of these are in Debian's apt
# repos at all (unlike neovim/delta/zellij/eza above, which are apt-present
# but too old/missing — these just aren't packaged), and aliases.zsh aliases
# dig/du/curl/jq to them unconditionally, so a missing binary here breaks a
# basic alias, not just a nice-to-have. Handles both shapes GitHub releases
# use: a .tar.gz archive to extract, or a bare binary asset to use as-is.
install_github_binary() {
  local repo="$1" asset_pattern="$2" binary_name="$3"
  local url; url="$(gh_latest_url "$repo" "$asset_pattern")"
  if [[ "$asset_pattern" == *.tar.gz ]]; then
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL "$url" | tar -xz -C "$tmp"
    find "$tmp" -name "$binary_name" -type f -exec cp {} "$LOCAL_BIN/$binary_name" \;
    rm -rf "$tmp"
  else
    curl -fsSL "$url" -o "$LOCAL_BIN/$binary_name"
  fi
  chmod +x "$LOCAL_BIN/$binary_name"
}

install_doggo() {
  # doggo's release arch strings already match `uname -m` as-is.
  install_github_binary mr-karan/doggo "doggo-linux-${ARCH}.tar.gz" doggo
}

install_dua() {
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="x86_64-unknown-linux-musl"  ;;
    aarch64) asset_arch="aarch64-unknown-linux-musl" ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac
  install_github_binary Byron/dua-cli "dua-v.*-${asset_arch}.tar.gz" dua
}

install_curlie() {
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="amd64" ;;
    aarch64) asset_arch="arm64" ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac
  install_github_binary rs/curlie "curlie_.*_linux_${asset_arch}.tar.gz" curlie
}

install_jaq() {
  # jaq's release assets are bare binaries, not archives.
  local asset_arch
  case "$ARCH" in
    x86_64)  asset_arch="x86_64-unknown-linux-gnu"  ;;
    aarch64) asset_arch="aarch64-unknown-linux-gnu" ;;
    *) printf 'Unsupported arch: %s\n' "$ARCH"; return 1 ;;
  esac
  install_github_binary 01mf02/jaq "jaq-${asset_arch}\$" jaq
}

# +------------------+
# | CONFIG SYMLINKS  |
# +------------------+

link_configs() {
  ln -sf "$DOTFILES_DIR/zsh/.zshenv"           "$HOME/.zshenv"

  ln -sf "$DOTFILES_DIR/theme/zsh-fsh/themes/catppuccin-mocha.ini" \
         "$XDG_CONFIG_HOME/fsh/catppuccin-mocha.ini"
  ln -sf "$DOTFILES_DIR/theme/eza/themes/mocha/catppuccin-mocha-mauve.yml" \
         "$XDG_CONFIG_HOME/eza/theme.yml"

  ln -sf "$DOTFILES_DIR/nvim/init.lua"         "$XDG_CONFIG_HOME/nvim/init.lua"
  ln -sfn "$DOTFILES_DIR/nvim/lua"             "$XDG_CONFIG_HOME/nvim/lua"
  ln -sf "$DOTFILES_DIR/nvim/lazy-lock.json"   "$XDG_CONFIG_HOME/nvim/lazy-lock.json"

  ln -sf "$DOTFILES_DIR/zellij/config.kdl"     "$XDG_CONFIG_HOME/zellij/config.kdl"
  ln -sf "$DOTFILES_DIR/zellij/themes/catppuccin.kdl" \
         "$XDG_CONFIG_HOME/zellij/themes/catppuccin.kdl"
  ln -sf "$DOTFILES_DIR/zellij/layouts/default.kdl" \
         "$XDG_CONFIG_HOME/zellij/layouts/default.kdl"

  ln -sf "$DOTFILES_DIR/htoprc"                "$XDG_CONFIG_HOME/htop/htoprc"
  ln -sf "$DOTFILES_DIR/batconfig"             "$XDG_CONFIG_HOME/bat/config"
  ln -sf "$DOTFILES_DIR/theme/bat/themes/Catppuccin Mocha.tmTheme" \
         "$XDG_CONFIG_HOME/bat/themes/Catppuccin Mocha.tmTheme"

  ln -sf "$DOTFILES_DIR/git/attributes"        "$XDG_CONFIG_HOME/git/attributes"
  ln -sf "$DOTFILES_DIR/git/committemplate"    "$XDG_CONFIG_HOME/git/committemplate"
  ln -sf "$DOTFILES_DIR/git/config"            "$XDG_CONFIG_HOME/git/config"
  ln -sf "$DOTFILES_DIR/git/ignore"            "$XDG_CONFIG_HOME/git/ignore"
  ln -sf "$DOTFILES_DIR/theme/delta/catppuccin.gitconfig" \
         "$XDG_CONFIG_HOME/git/catppuccin.gitconfig"

  ln -sf "$DOTFILES_DIR/ripgreprc"             "$XDG_CONFIG_HOME/ripgrep/config"
  ln -sf "$DOTFILES_DIR/curlrc"                "$XDG_CONFIG_HOME/curlrc"
  ln -sf "$DOTFILES_DIR/tealdeerconfig.toml"   "$XDG_CONFIG_HOME/tealdeer/config.toml"

  ln -sf "$DOTFILES_DIR/ssh/config"            "$XDG_CONFIG_HOME/ssh/config"

  # Machine-specific SSH config (real hostnames/IPs, usernames) — deployed
  # config.local's `Include` expects this to exist, but it's deliberately
  # a plain local file, not something this repo tracks/symlinks, so it's
  # created once here and never touched again on later deploy runs.
  [[ -f "$XDG_CONFIG_HOME/ssh/config.local" ]] || touch "$XDG_CONFIG_HOME/ssh/config.local"

  if [[ ! -d "$HOME/.ssh" || -L "$HOME/.ssh" ]]; then
    ln -sf "$XDG_CONFIG_HOME/ssh"              "$HOME/.ssh"
  fi

  # Debian installs fd as fdfind; symlink so PATH references just work
  if command -v fdfind &>/dev/null && [[ ! -e "$LOCAL_BIN/fd" ]]; then
    ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  fi

  # Debian installs bat as batcat (name collision with another package);
  # symlink so PATH references just work
  if command -v batcat &>/dev/null && [[ ! -e "$LOCAL_BIN/bat" ]]; then
    ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  fi

  # Debian's lesspipe binary is lesspipe, not lesspipe.sh — match macOS name
  if command -v lesspipe &>/dev/null && [[ ! -e "$LOCAL_BIN/lesspipe.sh" ]]; then
    ln -sf "$(command -v lesspipe)" "$LOCAL_BIN/lesspipe.sh"
  fi
}

# +-------------+
# | ZSH PLUGINS |
# +-------------+
# On macOS these come from Homebrew; on Linux clone directly to XDG_DATA_HOME.
# .zshrc sources from $XDG_DATA_HOME/zsh/plugins/ on both platforms.

install_zsh_plugins() {
  local plugin_dir="$XDG_DATA_HOME/zsh/plugins"

  _clone_or_pull() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
      # A rewritten upstream default branch makes --ff-only fail; re-clone
      # rather than aborting the whole (required) deploy over one plugin.
      git -C "$dest" pull --ff-only --quiet || {
        rm -rf "$dest"
        git clone --depth=1 --quiet "$url" "$dest"
      }
    else
      git clone --depth=1 --quiet "$url" "$dest"
    fi
  }

  _clone_or_pull "https://github.com/romkatv/powerlevel10k"         "$plugin_dir/powerlevel10k"
  _clone_or_pull "https://github.com/hlissner/zsh-autopair"         "$plugin_dir/zsh-autopair"
  _clone_or_pull "https://github.com/zsh-users/zsh-autosuggestions" "$plugin_dir/zsh-autosuggestions"
  _clone_or_pull "https://github.com/wfxr/forgit"                   "$plugin_dir/forgit"
  # apt has no zsh-completions package (absent from Trixie's archive, and
  # unreliable across releases generally) — git-clone it like the others.
  _clone_or_pull "https://github.com/zsh-users/zsh-completions"     "$plugin_dir/zsh-completions"
}

# +-----+
# | ZSH |
# +-----+

set_default_shell() {
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    sudo usermod -s "$zsh_path" "$USER"
    printf '  Note: log out and back in for the new shell to take effect\n'
  fi
}

sync_submodules() {
  git -C "$DOTFILES_DIR" submodule sync
  git -C "$DOTFILES_DIR" submodule update --init --recursive
}

download_gitstatusd() {
  # CI=1 skips .zshrc's zellij auto-attach block — without it, this
  # non-tty interactive shell hits `exec zellij attach` and hangs forever
  # instead of just running the p10k/gitstatusd bootstrap it's here for.
  CI=1 zsh -is <<< ''
}

set_fsh() {
  CI=1 zsh -is <<< 'fast-theme -q XDG:catppuccin-mocha'
}

refresh_tldr() {
  tldr -u
}

# bat only ships Catppuccin as a built-in theme in fairly recent releases;
# batconfig requests "Catppuccin Mocha" unconditionally, and Debian's apt
# bat is old enough to have neither the built-in nor (until link_configs
# symlinks it in) the vendored theme/bat submodule copy — compile it into
# bat's cache regardless of version.
build_bat_cache() {
  bat cache --build
}

# Pre-grant zjstatus its permissions: it lives in the 1-row status bar pane,
# where permission prompts are known to not render/be usable
# (zellij-org/zellij#4749), so it can't realistically get them interactively.
# Without this, the layout's first-ever load can fail outright — including
# when triggered from .zshrc's auto-attach right after this script's own
# `exec zsh`, which then falls back to the outer shell with no visible error.
grant_zellij_permissions() {
  local perms_file="$XDG_CACHE_HOME/zellij/permissions.kdl"
  local zjstatus_url="https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm"
  [[ -f $perms_file ]] && grep -qF "$zjstatus_url" "$perms_file" && return 0
  mkdir -p "$(dirname "$perms_file")"
  cat >>"$perms_file" <<-KDL
	"$zjstatus_url" {
	    ReadApplicationState
	    ChangeApplicationState
	    RunCommands
	}
	KDL
}

set_neovim() {
  nvim --headless -c "helptags ALL" -c "qall"
}

# +--------------------+
# | EXECUTE FUNCTIONS  |
# +--------------------+

required "Creating directory tree"                create_directories
required "Bootstrapping apt"                      bootstrap_apt
required "Adding custom apt repositories"         add_apt_repos
required "Installing apt packages"                install_apt_packages
required "Installing Neovim from GitHub"          install_neovim
required "Installing git-delta from GitHub"       install_git_delta
required "Installing zellij from GitHub"          install_zellij
required "Installing eza from GitHub"             install_eza
required "Installing doggo from GitHub"           install_doggo
required "Installing dua from GitHub"             install_dua
required "Installing curlie from GitHub"          install_curlie
required "Installing jaq from GitHub"             install_jaq
required "Syncing submodules"                     sync_submodules
required "Linking config files"                   link_configs
required "Installing zsh plugins"                 install_zsh_plugins
required "Setting zsh as default shell"           set_default_shell
optional "Building bat theme cache"               build_bat_cache
optional "Downloading gitstatusd for p10k"        download_gitstatusd
optional "Setting fast-syntax-highlighting theme" set_fsh
optional "Refreshing TLDR pages"                  refresh_tldr
optional "Granting zellij plugin permissions"     grant_zellij_permissions
optional "Setting up Neovim plugins/LSPs"         set_neovim

# set_default_shell only takes effect on the next login; exec straight into
# zsh so this session lands there too instead of staying on bash until then.
# Skip if stdout isn't a real terminal (e.g. output is being piped/logged).
if [[ -t 1 ]]; then
  # Clear the screen first — without it, zsh (then, on this VM's first-ever
  # session, .zshrc's zellij auto-attach, then p10k's instant prompt) all
  # initialize on top of this whole script's leftover scrollback instead of
  # the blank terminal a real login gives them, which is what left the
  # prompt looking broken until the next full VM restart.
  clear
  exec zsh
fi
