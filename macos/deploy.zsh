#!/usr/bin/env zsh

# Load Zsh modules for managing files
zmodload -m -F zsh/files b:zf_ln b:zf_mkdir

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Get the current script directory
DEPLOY_DIR=$(dirname $(realpath $0))
DOTFILES_DIR=$DEPLOY_DIR:h

# Default XDG paths
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

# XDG_RUNTIME_DIR is for non-persistent, temporary files (like sockets).
# On macOS, the system-provided $TMPDIR is the correct, secure,
# and non-persistent location to use.
XDG_RUNTIME_DIR=$TMPDIR

# +---------+
# | RUNNERS |
# +---------+

# A critical step: abort the whole deploy if it fails.
required() {
  local desc=$1; shift
  print "$desc..."
  local output
  if output=$("$@" 2>&1); then
    print "  ...done"
  else
    print "  FAILED:"
    print "$output"
    exit 1
  fi
}

# A best-effort step: print the failure but let deploy continue.
optional() {
  local desc=$1; shift
  print "$desc..."
  local output
  if output=$("$@" 2>&1); then
    print "  ...done"
  else
    print "  FAILED (continuing):"
    print "$output"
  fi
}

# Function to create required directories
create_directories() {
  setopt local_options err_exit
  zf_mkdir -p $XDG_CONFIG_HOME/{bat/themes,direnv,eza,git,htop,ghostty,ripgrep,tealdeer,fsh,homebrew,nvim}
  zf_mkdir -p $XDG_CONFIG_HOME/zellij/{themes,layouts}
  zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh/completions,direnv,bat,tealdeer,fast-syntax-highlighting,git-credential-cache}
  zf_mkdir -p $XDG_DATA_HOME/{nvim,terminfo,direnv,zoxide,go,zsh/plugins}
  zf_mkdir -p $XDG_STATE_HOME/{zsh,less}
  zf_mkdir -p $XDG_RUNTIME_DIR/Homebrew
  zf_mkdir -p $XDG_CONFIG_HOME/claude
  zf_mkdir -pm 700 $XDG_CONFIG_HOME/ssh
}

# Symlink config files
link_configs() {
  setopt local_options err_exit
  # AGENTS.md is the source of truth; CLAUDE.md is a gitignored symlink so Claude
  # Code picks up the same guidance without duplicating it
  zf_ln -sf AGENTS.md $DOTFILES_DIR/CLAUDE.md

  # Claude Code agent config → $CLAUDE_CONFIG_DIR/rules ($XDG_CONFIG_HOME/claude/rules).
  # Claude Code auto-discovers and loads every *.md under rules/ recursively and
  # unconditionally — no loader file or @import wiring needed. See claude/README.md.
  # Symlinked as one directory so universal/tools/platform (and any gitignored
  # private file dropped inside them) all come along with zero per-file wiring.
  # One-time cleanup of prior layouts (claude/CLAUDE.md + claude/fragments/ from the
  # old loader design; a real claude/rules/ dir of individual symlinks from the
  # per-file-glob design) — safe since deploy fully owns all of these paths.
  rm -f $XDG_CONFIG_HOME/claude/CLAUDE.md
  rm -rf $XDG_CONFIG_HOME/claude/fragments
  rm -rf $XDG_CONFIG_HOME/claude/rules
  zf_ln -sfn $DOTFILES_DIR/claude/rules $XDG_CONFIG_HOME/claude/rules

  # Claude Code subagents → $CLAUDE_CONFIG_DIR/agents. Same one-directory symlink as
  # rules/ above — every *.md under agents/ is discovered recursively, no per-agent
  # wiring. See claude/README.md § Subagents.
  rm -rf $XDG_CONFIG_HOME/claude/agents
  zf_ln -sfn $DOTFILES_DIR/claude/agents $XDG_CONFIG_HOME/claude/agents

  # Claude Code skills → $CLAUDE_CONFIG_DIR/skills. Same one-directory symlink as
  # rules/ and agents/ above — every skill's SKILL.md under skills/<name>/ is
  # discovered recursively, no per-skill wiring. See claude/README.md § Skills.
  rm -rf $XDG_CONFIG_HOME/claude/skills
  zf_ln -sfn $DOTFILES_DIR/claude/skills $XDG_CONFIG_HOME/claude/skills

  # Claude Code global settings (telemetry/error-reporting/auto-update opt-outs).
  zf_ln -sf $DOTFILES_DIR/claude/settings.json $XDG_CONFIG_HOME/claude/settings.json

  zf_ln -sf $DOTFILES_DIR/zsh/.zshenv $HOME/.zshenv
  zf_ln -sf $DOTFILES_DIR/theme/zsh-fsh/themes/catppuccin-mocha.ini $XDG_CONFIG_HOME/fsh/catppuccin-mocha.ini
  zf_ln -sf $DOTFILES_DIR/theme/eza/themes/mocha/catppuccin-mocha-mauve.yml $XDG_CONFIG_HOME/eza/theme.yml

  zf_ln -sf $DOTFILES_DIR/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
  zf_ln -sfn $DOTFILES_DIR/nvim/lua $XDG_CONFIG_HOME/nvim/lua
  zf_ln -sf $DOTFILES_DIR/nvim/lazy-lock.json $XDG_CONFIG_HOME/nvim/lazy-lock.json

  zf_ln -sf $DOTFILES_DIR/ghostty/config $XDG_CONFIG_HOME/ghostty/config

  zf_ln -sf $DOTFILES_DIR/zellij/config.kdl $XDG_CONFIG_HOME/zellij/config.kdl
  zf_ln -sf $DOTFILES_DIR/zellij/themes/catppuccin.kdl $XDG_CONFIG_HOME/zellij/themes/catppuccin.kdl
  zf_ln -sf $DOTFILES_DIR/zellij/layouts/default.kdl $XDG_CONFIG_HOME/zellij/layouts/default.kdl

  zf_ln -sf $DOTFILES_DIR/htoprc $XDG_CONFIG_HOME/htop/htoprc

  zf_ln -sf $DOTFILES_DIR/batconfig $XDG_CONFIG_HOME/bat/config
  zf_ln -sf $DOTFILES_DIR/theme/bat/themes/"Catppuccin Mocha.tmTheme" $XDG_CONFIG_HOME/bat/themes/"Catppuccin Mocha.tmTheme"

  zf_ln -sf $DOTFILES_DIR/git/attributes $XDG_CONFIG_HOME/git/attributes
  zf_ln -sf $DOTFILES_DIR/git/committemplate $XDG_CONFIG_HOME/git/committemplate
  zf_ln -sf $DOTFILES_DIR/git/config $XDG_CONFIG_HOME/git/config
  zf_ln -sf $DOTFILES_DIR/git/ignore $XDG_CONFIG_HOME/git/ignore
  zf_ln -sf $DOTFILES_DIR/theme/delta/catppuccin.gitconfig $XDG_CONFIG_HOME/git/catppuccin.gitconfig

  zf_ln -sf $DOTFILES_DIR/ripgreprc $XDG_CONFIG_HOME/ripgrep/config
  zf_ln -sf $DOTFILES_DIR/curlrc $XDG_CONFIG_HOME/curlrc
  zf_ln -sf $DOTFILES_DIR/tealdeerconfig.toml $XDG_CONFIG_HOME/tealdeer/config.toml

  zf_ln -sf $DEPLOY_DIR/brew.env $XDG_CONFIG_HOME/homebrew/brew.env
  zf_ln -sf $DEPLOY_DIR/Brewfile $XDG_CONFIG_HOME/homebrew/Brewfile

  zf_ln -sf $DOTFILES_DIR/ssh/config $XDG_CONFIG_HOME/ssh/config

  # Machine-specific SSH config (real hostnames/IPs, usernames) — deployed
  # config.local's `Include` expects this to exist, but it's deliberately
  # a plain local file, not something this repo tracks/symlinks, so it's
  # created once here and never touched again on later deploy runs.
  [[ -f $XDG_CONFIG_HOME/ssh/config.local ]] || touch $XDG_CONFIG_HOME/ssh/config.local

  # ~/.ssh → ~/.config/ssh (XDG via symlink). Skip if ~/.ssh is already a
  # real directory — the user must migrate keys manually first.
  if [[ ! -d $HOME/.ssh || -L $HOME/.ssh ]]; then
    zf_ln -sf $XDG_CONFIG_HOME/ssh $HOME/.ssh
  fi
}

# +----------+
# | Homebrew |
# +----------+

# Check for Homebrew
install_homebrew() {
  setopt local_options err_exit
  if [[ -z $(command -v brew) ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

# Install Brewfile packages
install_brewfile() {
  brew bundle --file=$DEPLOY_DIR/Brewfile
}

# Activate the git hooks in lefthook.yml: pre-commit (zsh syntax, shellcheck,
# actionlint — mirrors of what ci.yml/pr-guards.yml enforce) and pre-push (the
# .envrc.local.example sync check). A single `lefthook install` covers every
# hook type declared as a top-level key in lefthook.yml.
install_lefthook_hooks() {
  # lefthook has no -C/--cwd equivalent; it discovers .git relative to the
  # working directory, so it has to actually run from inside the repo.
  (cd $DOTFILES_DIR && lefthook install -f)
}

# Point $XDG_DATA_HOME/zsh/plugins/* at Homebrew's copies so .zshrc can use
# the same paths on both macOS and Linux.
link_zsh_plugins() {
  setopt local_options err_exit
  local -A plugin_srcs=(
    powerlevel10k       $HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k
    zsh-autosuggestions $HOMEBREW_PREFIX/share/zsh-autosuggestions
    zsh-autopair        $HOMEBREW_PREFIX/share/zsh-autopair
  )
  local name
  for name in ${(k)plugin_srcs}; do
    # Fail loudly rather than symlink a path that doesn't exist yet — a
    # dangling link here would surface later as an opaque `source` error
    # at shell startup instead of a clear deploy-time failure.
    [[ -e $plugin_srcs[$name] ]] || { print "  Missing $name at $plugin_srcs[$name]" >&2; return 1 }
    zf_ln -sf $plugin_srcs[$name] $XDG_DATA_HOME/zsh/plugins/$name
  done
}

# Sync Git submodules
sync_submodules() {
  setopt local_options err_exit
  git -C $DOTFILES_DIR submodule sync
  git -C $DOTFILES_DIR submodule update --init --recursive
}

# Trigger zsh run to download gitstatusd
download_gitstatusd() {
  # CI=1 skips .zshrc's zellij auto-attach block — without it, this
  # non-tty interactive shell hits `exec zellij attach` and hangs forever
  # instead of just running the p10k/gitstatusd bootstrap it's here for.
  CI=1 $SHELL -is <<< ''
}

set_fsh() {
  CI=1 $SHELL -is <<< 'fast-theme -q XDG:catppuccin-mocha'
}

# Generate completions for tools with no Homebrew-shipped zsh completion file
generate_completions() {
  dua completions zsh > $XDG_CACHE_HOME/zsh/completions/_dua
  doggo completions zsh > $XDG_CACHE_HOME/zsh/completions/_doggo
}

# Refresh TLDR pages
refresh_tldr() {
  tldr -u
}

# Install Ghostty's xterm-ghostty terminfo into the XDG terminfo dir.
# Needed because TERMINFO points at $XDG_DATA_HOME/terminfo and macOS's system
# terminfo predates Ghostty, so the bundled entry must be compiled in here.
generate_ghostty_terminfo() {
  local ghostty_ti="/Applications/Ghostty.app/Contents/Resources/terminfo"
  [[ -d $ghostty_ti ]] || return 0
  $HOMEBREW_PREFIX/opt/ncurses/bin/infocmp -x -A $ghostty_ti xterm-ghostty \
    | $HOMEBREW_PREFIX/opt/ncurses/bin/tic -x -o "$XDG_DATA_HOME/terminfo" -
}

# bat only ships Catppuccin as a built-in theme in fairly recent releases;
# batconfig requests "Catppuccin Mocha" unconditionally, so compile the
# vendored theme/bat submodule copy into bat's cache regardless of version.
build_bat_cache() {
  bat cache --build
}

# Pre-grant zjstatus its permissions: it lives in the 1-row status bar pane,
# where permission prompts are known to not render/be usable
# (zellij-org/zellij#4749), so it can't realistically get them interactively.
grant_zellij_permissions() {
  local perms_file="$HOME/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl"
  local zjstatus_url="https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm"
  [[ -f $perms_file ]] && grep -qF "$zjstatus_url" "$perms_file" && return 0
  zf_mkdir -p "${perms_file:h}"
  cat >>"$perms_file" <<-KDL
	"$zjstatus_url" {
	    ReadApplicationState
	    ChangeApplicationState
	    RunCommands
	}
	KDL
}

set_neovim() {
  # Launch nvim to trigger Lazy to download plugins and Mason to install any
  # LSPs/formatters declared via ensure_installed (LazyVim's own lang extras
  # and lsp core plugin both do this automatically on startup — no separate
  # install command needed).
  command nvim --headless -c "helptags ALL" -c "qall"
}

# +-------------------+
# | EXECUTE FUNCTIONS |
# +-------------------+

required "Creating required directory tree"    create_directories
required "Linking config files"                link_configs
required "Checking for Homebrew"                install_homebrew
required "Installing Brewfile packages"        install_brewfile
optional "Installing lefthook hooks"           install_lefthook_hooks
required "Linking zsh plugins"                 link_zsh_plugins
required "Syncing submodules"                  sync_submodules
optional "Building bat theme cache"            build_bat_cache
optional "Downloading gitstatusd for p10k"     download_gitstatusd
optional "Setting fast-syntax-highlighting theme" set_fsh
optional "Generating dua/doggo completions"    generate_completions
optional "Refreshing TLDR pages"               refresh_tldr
optional "Installing Ghostty terminfo"         generate_ghostty_terminfo
optional "Granting zellij plugin permissions"  grant_zellij_permissions
optional "Setting up Neovim plugins/LSPs"      set_neovim
