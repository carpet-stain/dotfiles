#!/usr/bin/env bash
# Deploy dotfiles on Debian 12 (Bookworm).
# Run as a regular user with passwordless sudo (the default on OrbStack VMs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Anchor to the main checkout via the shared .git dir: a linked worktree is
# deleted after its task, leaving every symlink into it dangling.
GIT_COMMON_DIR="$(git -C "$SCRIPT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [[ -n "$GIT_COMMON_DIR" ]]; then
  DOTFILES_DIR="$(dirname "$GIT_COMMON_DIR")"
else
  DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
fi

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="$HOME/.local/bin"

# Only x86_64 has binaries.lock entries; any other arch fails fetch_verified's
# lookup loudly rather than being silently unsupported.
ARCH="$(uname -m)"
# shellcheck disable=SC1091 # /etc/os-release is a system file, not part of this repo
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")" # e.g. bookworm, bullseye

# A non-login or minimal shell may lack $LOCAL_BIN and the system dirs, which
# surfaces as "command not found" for a binary this same run just installed.
export PATH="$LOCAL_BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# +---------+
# | RUNNERS |
# +---------+

required() {
  local desc="$1"
  shift
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
  local desc="$1"
  shift
  printf '%s...\n' "$desc"
  local output
  if output=$("$@" 2>&1); then
    printf '  ...done\n'
  else
    printf '  FAILED (continuing):\n%s\n' "$output"
  fi
}

# required()'s contract, but streams output live for long steps. The `if`
# around the pipeline keeps set -e from short-circuiting past FAILED.
stream() {
  local desc="$1"
  shift
  printf '%s...\n' "$desc"
  local logfile
  logfile="$(mktemp)"
  if "$@" 2>&1 | tee "$logfile"; then
    printf '  ...done\n'
    rm -f "$logfile"
  else
    local exit_code=$?
    printf '  FAILED (exit %s) — log: %s\n' "$exit_code" "$logfile"
    exit 1
  fi
}

# +----------------+
# | XDG DIRS       |
# +----------------+

create_directories() {
  mkdir -p \
    "$XDG_CONFIG_HOME/aichat" \
    "$XDG_CONFIG_HOME/bat/themes" \
    "$XDG_CONFIG_HOME/direnv" \
    "$XDG_CONFIG_HOME/eza/themes/mocha" \
    "$XDG_CONFIG_HOME/git" \
    "$XDG_CONFIG_HOME/htop" \
    "$XDG_CONFIG_HOME/nvim" \
    "$XDG_CONFIG_HOME/ripgrep" \
    "$XDG_CONFIG_HOME/tealdeer" \
    "$XDG_CONFIG_HOME/zellij/themes" \
    "$XDG_CONFIG_HOME/zellij/layouts" \
    "$XDG_CONFIG_HOME/zsh-patina" \
    "$XDG_CACHE_HOME/bat" \
    "$XDG_CACHE_HOME/direnv" \
    "$XDG_CACHE_HOME/nvim" \
    "$XDG_CACHE_HOME/tealdeer" \
    "$XDG_CACHE_HOME/zsh/completions" \
    "$XDG_DATA_HOME/direnv" \
    "$XDG_DATA_HOME/go" \
    "$XDG_DATA_HOME/nvim" \
    "$XDG_DATA_HOME/zoxide" \
    "$XDG_DATA_HOME/zsh/plugins" \
    "$XDG_STATE_HOME/less" \
    "$XDG_STATE_HOME/zsh" \
    "$LOCAL_BIN"
  mkdir -p "$HOME/.claude"
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
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    printf 'deb [arch=%s signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
      "$(dpkg --print-architecture)" |
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  fi

  # NodeSource — Node 20 LTS
  if ! node --version 2>/dev/null | grep -q '^v20'; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null
  fi

  # Backports for golang-go 1.22+ (stable's is too old for gopls). Derive the
  # suite from $CODENAME — a hardcoded one can wedge apt on another release.
  if ! grep -rq "${CODENAME}-backports" /etc/apt/sources.list* 2>/dev/null; then
    printf 'deb http://deb.debian.org/debian %s-backports main\n' "$CODENAME" |
      sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
  fi

  sudo apt-get update -qq
}

install_apt_packages() {
  # One transaction for everything: separate apt-get calls let a later one
  # silently remove a package an earlier one installed (zsh, tealdeer).
  local packages
  packages=$(grep -v '^\s*#' "$SCRIPT_DIR/Aptfile" | grep -v '^\s*$' | tr '\n' ' ')
  # pkg/release pins only that package, not its deps — so golang-src too.
  # shellcheck disable=SC2086
  sudo apt-get install -y --no-install-recommends \
    $packages "golang-go/${CODENAME}-backports" "golang-src/${CODENAME}-backports" gh nodejs
}

# +-------------------+
# | GITHUB BINARIES   |
# +-------------------+

# Tools too old or missing in Debian's apt repos, pinned in binaries.lock
# (version + sha256 per arch). Bump with update-binaries.sh.

# fetch_verified <tool> — download this arch's pinned asset from binaries.lock,
# verify its sha256 (fail-closed on mismatch), and echo the local file path.
fetch_verified() {
  local tool="$1" row url sha dest
  row="$(awk -F'\t' -v t="$tool" -v a="$ARCH" '$1==t && $2==a {print; exit}' "$SCRIPT_DIR/binaries.lock")"
  if [[ -z "$row" ]]; then
    printf 'no pinned %s entry for %s in binaries.lock\n' "$ARCH" "$tool" >&2
    return 1
  fi
  url="$(cut -f4 <<<"$row")"
  sha="$(cut -f5 <<<"$row")"
  dest="$(mktemp)"

  # Optional CI download cache keyed by the pinned sha256, off by default. The
  # sha is re-verified below, so a hit is as trustworthy as a fresh download.
  local cached=""
  [[ -n "${BINARIES_CACHE_DIR:-}" ]] && cached="$BINARIES_CACHE_DIR/$sha"
  if [[ -n "$cached" && -f "$cached" ]]; then
    cp "$cached" "$dest"
  elif ! curl -fsSL "$url" -o "$dest"; then
    printf 'download failed: %s\n' "$url" >&2
    rm -f "$dest"
    return 1
  fi
  if ! printf '%s  %s' "$sha" "$dest" | sha256sum -c --status -; then
    printf 'sha256 mismatch for %s (%s) — expected %s\n' "$tool" "$ARCH" "$sha" >&2
    rm -f "$dest"
    return 1
  fi
  # Populate the cache on a miss so the next run hits it.
  if [[ -n "$cached" && ! -f "$cached" ]]; then
    mkdir -p "$BINARIES_CACHE_DIR"
    cp "$dest" "$cached"
  fi
  printf '%s' "$dest"
}

# install_tool <tool> <binary> — single-binary tools; handles a tar.gz, a zip
# (selene/stylua), or a bare binary.
install_tool() {
  local tool="$1" binary="$2" archive
  archive="$(fetch_verified "$tool")" || return 1
  if tar -tzf "$archive" >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp -d)"
    tar -xzf "$archive" -C "$tmp"
    find "$tmp" -name "$binary" -type f -exec cp {} "$LOCAL_BIN/$binary" \;
    rm -rf "$tmp"
  elif unzip -tq "$archive" >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp -d)"
    unzip -q "$archive" -d "$tmp"
    find "$tmp" -name "$binary" -type f -exec cp {} "$LOCAL_BIN/$binary" \;
    rm -rf "$tmp"
  else
    cp "$archive" "$LOCAL_BIN/$binary"
  fi
  rm -f "$archive"
  if [[ ! -f "$LOCAL_BIN/$binary" ]]; then
    printf 'install_tool: %s not found after installing %s\n' "$binary" "$tool" >&2
    return 1
  fi
  chmod +x "$LOCAL_BIN/$binary"
}

# neovim needs its runtime (share/nvim) beside the binary, so it can't use the
# generic single-binary installer above.
install_neovim() {
  local archive
  archive="$(fetch_verified neovim)" || return 1
  local tmp
  tmp="$(mktemp -d)"
  tar -xzf "$archive" -C "$tmp"
  local src
  src="$(find "$tmp" -maxdepth 1 -name 'nvim-linux-*' -type d | head -1)"

  cp "$src/bin/nvim" "$LOCAL_BIN/nvim"
  chmod +x "$LOCAL_BIN/nvim"
  # Runtime must sit at $HOME/.local/share/nvim/runtime relative to the binary
  cp -r "$src/share/nvim" "$XDG_DATA_HOME/"
  [[ -d "$src/lib" ]] && {
    mkdir -p "$HOME/.local/lib"
    cp -r "$src/lib/." "$HOME/.local/lib/"
  }
  rm -rf "$tmp" "$archive"
}

# +------------------+
# | CONFIG SYMLINKS  |
# +------------------+

link_configs() {
  ln -sf "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

  # → ~/.claude/{rules,agents,skills}, layered from claude/global/ (submodule)
  # plus repo-local exceptions — see claude/README.md § Deployment; ADR-0039.

  # The rm's clear prior layouts deploy still owns.
  rm -f "$HOME/.claude/CLAUDE.md"
  rm -rf "$HOME/.claude/fragments"
  rm -rf "$HOME/.claude/rules"
  rm -rf "$HOME/.claude/agents"
  rm -rf "$HOME/.claude/skills"

  mkdir -p "$HOME/.claude/rules"
  ln -sfn "$DOTFILES_DIR/claude/global/rules/domain" "$HOME/.claude/rules/domain"
  ln -sfn "$DOTFILES_DIR/claude/global/rules/tools" "$HOME/.claude/rules/tools"
  ln -sfn "$DOTFILES_DIR/claude/global/rules/universal" "$HOME/.claude/rules/universal"

  mkdir -p "$HOME/.claude/rules/platform"
  ln -sf "$DOTFILES_DIR/claude/global/rules/platform/github.md" "$HOME/.claude/rules/platform/github.md"
  ln -sfn "$DOTFILES_DIR/claude/rules/platform/private" "$HOME/.claude/rules/platform/private"

  # agents/ moved to claude/global/ entirely (dotfiles#569) — whole-dir symlink.
  ln -sfn "$DOTFILES_DIR/claude/global/agents" "$HOME/.claude/agents"

  # verify-nvim-config stays local: it verifies *this* repo's nvim config.
  mkdir -p "$HOME/.claude/skills"
  shopt -s nullglob
  for d in "$DOTFILES_DIR"/claude/global/skills/*/; do
    d=${d%/}
    ln -sfn "$d" "$HOME/.claude/skills/$(basename "$d")"
  done
  shopt -u nullglob
  ln -sfn "$DOTFILES_DIR/claude/skills/verify-nvim-config" "$HOME/.claude/skills/verify-nvim-config"

  # Claude Code global settings (telemetry/error-reporting/auto-update opt-outs).
  ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

  # Mocha only: Linux hardcodes THEME_MODE=dark (zsh/.zshenv, #439), so a
  # latte variant could never be selected. See ADR-0034.
  ln -sf "$DOTFILES_DIR/zsh-patinaconfig-mocha.toml" "$XDG_CONFIG_HOME/zsh-patina/config-mocha.toml"
  ln -sf "$DOTFILES_DIR/theme/eza/themes/mocha/catppuccin-mocha-mauve.yml" \
    "$XDG_CONFIG_HOME/eza/themes/mocha/theme.yml"

  ln -sf "$DOTFILES_DIR/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
  ln -sfn "$DOTFILES_DIR/nvim/lua" "$XDG_CONFIG_HOME/nvim/lua"
  ln -sf "$DOTFILES_DIR/nvim/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"

  # Per-file, not the whole dir — aichat writes runtime files into its config
  # dir and a whole-dir symlink would land them inside the repo (#511).
  ln -sf "$DOTFILES_DIR/aichat/config.yaml" "$XDG_CONFIG_HOME/aichat/config.yaml"
  ln -sfn "$DOTFILES_DIR/aichat/roles" "$XDG_CONFIG_HOME/aichat/roles"

  ln -sf "$DOTFILES_DIR/zellij/config.kdl" "$XDG_CONFIG_HOME/zellij/config.kdl"
  ln -sf "$DOTFILES_DIR/zellij/themes/catppuccin.kdl" \
    "$XDG_CONFIG_HOME/zellij/themes/catppuccin.kdl"
  ln -sf "$DOTFILES_DIR/zellij/layouts/default.kdl" \
    "$XDG_CONFIG_HOME/zellij/layouts/default.kdl"

  ln -sf "$DOTFILES_DIR/htoprc" "$XDG_CONFIG_HOME/htop/htoprc"
  ln -sf "$DOTFILES_DIR/batconfig" "$XDG_CONFIG_HOME/bat/config"
  ln -sf "$DOTFILES_DIR/theme/bat/themes/Catppuccin Mocha.tmTheme" \
    "$XDG_CONFIG_HOME/bat/themes/Catppuccin Mocha.tmTheme"

  ln -sf "$DOTFILES_DIR/git/attributes" "$XDG_CONFIG_HOME/git/attributes"
  ln -sf "$DOTFILES_DIR/git/committemplate" "$XDG_CONFIG_HOME/git/committemplate"
  ln -sf "$DOTFILES_DIR/git/config" "$XDG_CONFIG_HOME/git/config"
  ln -sf "$DOTFILES_DIR/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
  ln -sf "$DOTFILES_DIR/theme/delta/catppuccin.gitconfig" \
    "$XDG_CONFIG_HOME/git/catppuccin.gitconfig"

  # Backs the `pr`/`new`/`sync` aliases (git/config) — must be on PATH as bare
  # commands, since git/config is used from any repo.
  ln -sf "$DOTFILES_DIR/scripts/aichat-pane.sh" "$LOCAL_BIN/aichat-pane"
  ln -sf "$DOTFILES_DIR/scripts/git-pr-link.sh" "$LOCAL_BIN/git-pr-link"
  ln -sf "$DOTFILES_DIR/scripts/git-new.sh" "$LOCAL_BIN/git-new"
  ln -sf "$DOTFILES_DIR/scripts/git-sync.sh" "$LOCAL_BIN/git-sync"

  ln -sf "$DOTFILES_DIR/ripgreprc" "$XDG_CONFIG_HOME/ripgrep/config"
  ln -sf "$DOTFILES_DIR/curlrc" "$XDG_CONFIG_HOME/curlrc"
  ln -sf "$DOTFILES_DIR/tealdeerconfig.toml" "$XDG_CONFIG_HOME/tealdeer/config.toml"

  # direnv auto-sources ~/.config/direnv/lib/*.sh before a repo's .envrc
  # — use_github_token (the shared vended-token bridge, #195) lives here.
  ln -sfn "$DOTFILES_DIR/direnv/lib" "$XDG_CONFIG_HOME/direnv/lib"

  ln -sf "$DOTFILES_DIR/ssh/config" "$XDG_CONFIG_HOME/ssh/config"

  # config.local holds real hostnames — deliberately untracked. Created once
  # here because the deployed config's `Include` expects it to exist.
  [[ -f "$XDG_CONFIG_HOME/ssh/config.local" ]] || touch "$XDG_CONFIG_HOME/ssh/config.local"

  if [[ ! -d "$HOME/.ssh" || -L "$HOME/.ssh" ]]; then
    ln -sf "$XDG_CONFIG_HOME/ssh" "$HOME/.ssh"
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

# .zshrc sources these from $XDG_DATA_HOME/zsh/plugins/; Linux points them at
# the vendored submodules, so sync_submodules must run first.

install_zsh_plugins() {
  local plugin_dir="$XDG_DATA_HOME/zsh/plugins"
  local name src
  for name in powerlevel10k zsh-autopair zsh-completions; do
    src="$DOTFILES_DIR/zsh/plugins/$name"
    if [[ ! -e "$src" ]]; then
      printf '  Missing submodule %s at %s (run: git submodule update --init)\n' "$name" "$src" >&2
      return 1
    fi
    # rm first: `ln -sfn` into an existing real dir nests the link inside it.
    # ${plugin_dir:?} guards against ever rm -rf'ing / if the var were empty.
    rm -rf "${plugin_dir:?}/$name"
    ln -sfn "$src" "$plugin_dir/$name"
  done
}

# +-----+
# | ZSH |
# +-----+

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    sudo usermod -s "$zsh_path" "$USER"
    printf '  Note: log out and back in for the new shell to take effect\n'
  fi
}

sync_submodules() {
  git -C "$DOTFILES_DIR" submodule sync
  git -C "$DOTFILES_DIR" submodule update --init --recursive
}

# Prefetches origin so `git new`'s fetch is a no-op. Scoped to this repo —
# run `git maintenance start` by hand in any other one.
enable_git_maintenance() {
  git -C "$DOTFILES_DIR" maintenance start
}

download_gitstatusd() {
  # CI=1 skips .zshrc's zellij auto-attach — without it this non-tty
  # interactive shell hits `exec zellij attach` and hangs forever.
  CI=1 zsh -is <<<''
}

# `deja import` isn't idempotent (double-counts), so the marker file — not the
# db's existence — gates it; --file is required, HISTFILE isn't exported here.
import_deja_history() {
  local marker="$XDG_STATE_HOME/deja/.imported"
  [[ -f "$marker" ]] && return
  deja import --file "$XDG_STATE_HOME/zsh/history"
  mkdir -p "$(dirname "$marker")"
  touch "$marker"
}

refresh_tldr() {
  tldr -u
}

# Debian's bat is old enough to lack the built-in Catppuccin theme BAT_THEME
# requests (zsh/.zshenv), so build the cache regardless of version.
build_bat_cache() {
  bat cache --build
}

# zjstatus can't be granted interactively — prompts don't render in the
# status-bar pane (zellij-org/zellij#4749), so the first load fails outright.
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

# ~/.terminfo, not $XDG_DATA_HOME: ncurses' default search path only covers
# the former, and this is bash — see AGENTS.md's XDG exceptions.
generate_ghostty_terminfo() {
  tic -x -o "$HOME/.terminfo" "$DOTFILES_DIR/ghostty/xterm-ghostty.terminfo"
}

# +--------------------+
# | EXECUTE FUNCTIONS  |
# +--------------------+

required "Creating directory tree" create_directories
required "Bootstrapping apt" bootstrap_apt
required "Adding custom apt repositories" add_apt_repos
stream "Installing apt packages" install_apt_packages
stream "Installing Neovim" install_neovim
required "Installing git-delta" install_tool delta delta
required "Installing zellij" install_tool zellij zellij
required "Installing eza" install_tool eza eza
required "Installing doggo" install_tool doggo doggo
required "Installing dua" install_tool dua dua
required "Installing curlie" install_tool curlie curlie
required "Installing jaq" install_tool jaq jaq
required "Installing golangci-lint" install_tool golangci-lint golangci-lint
required "Installing lua-language-server" install_tool lua-language-server lua-language-server
required "Installing ruff" install_tool ruff ruff
required "Installing stylua" install_tool stylua stylua
required "Installing selene" install_tool selene selene
required "Installing deja" install_tool deja deja
required "Installing zsh-patina" install_tool zsh-patina zsh-patina
# Pinned, not apt: Debian's fzf 0.38 lacks `--zsh` (.zshrc needs 0.48+) and
# the `selected-bg` color — both silently no-op instead of erroring (#442).
required "Installing fzf" install_tool fzf fzf

# Pinned go install/npm, checksum-verified like binaries.lock — see ADR-0030.
# Top level: required()/optional() subshell, so the PATH mutation wouldn't survive.
printf 'Installing go-installed dev tools...\n'
export GOPATH="$XDG_DATA_HOME/go" # must match zsh/.zshenv's GOPATH
PATH="$GOPATH/bin:$PATH"
go install golang.org/x/tools/gopls@v0.23.0
go install golang.org/x/tools/cmd/goimports@v0.48.0
go install mvdan.cc/gofumpt@v0.10.0
go install github.com/fatih/gomodifytags@v1.17.0
go install github.com/josharian/impl@v1.5.0
go install github.com/go-delve/delve/cmd/dlv@v1.27.0
printf '  ...done\n'

# Explicit --prefix: npm's default global prefix needs sudo on Debian's apt
# nodejs, and this keeps the install sudo-free and XDG-scoped.
printf 'Installing npm-installed dev tools...\n'
NPM_GLOBAL_PREFIX="$XDG_DATA_HOME/npm-global"
npm install -g --prefix "$NPM_GLOBAL_PREFIX" pyright@1.1.411 bash-language-server@5.6.0
PATH="$NPM_GLOBAL_PREFIX/bin:$PATH"
printf '  ...done\n'

required "Syncing submodules" sync_submodules
optional "Enabling git maintenance" enable_git_maintenance
required "Linking config files" link_configs
required "Installing zsh plugins" install_zsh_plugins
required "Setting zsh as default shell" set_default_shell
required "Installing Ghostty terminfo" generate_ghostty_terminfo
optional "Building bat theme cache" build_bat_cache
optional "Downloading gitstatusd for p10k" download_gitstatusd
optional "Importing zsh history into deja" import_deja_history
optional "Refreshing TLDR pages" refresh_tldr
optional "Granting zellij plugin permissions" grant_zellij_permissions
optional "Setting up Neovim plugins/LSPs" set_neovim

# set_default_shell only applies at next login, so exec into zsh now. Skipped
# when stdout isn't a tty (piped or logged).
if [[ -t 1 ]]; then
  # Clear first — zsh, zellij auto-attach, and p10k's instant prompt otherwise
  # init on top of this script's scrollback and the prompt renders broken.
  clear
  exec zsh
fi
