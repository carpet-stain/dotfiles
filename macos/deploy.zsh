#!/usr/bin/env zsh

# Load Zsh modules for managing files
zmodload -m -F zsh/files b:zf_ln b:zf_mkdir

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Get the current script directory
DEPLOY_DIR=$(dirname $(realpath $0))

# Anchor to the main checkout's root via the shared .git dir, not wherever
# this script physically lives. A linked worktree (e.g. Claude Code session
# isolation) has its own directory that's deleted once its task is done —
# symlinking live $HOME/$XDG config at that ephemeral copy leaves every
# symlink dangling. --git-common-dir resolves to the main repo's .git
# regardless of which worktree invokes it, so this is safe from any of them.
GIT_COMMON_DIR=$(git -C $DEPLOY_DIR rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [[ -n $GIT_COMMON_DIR ]]; then
  DOTFILES_DIR=${GIT_COMMON_DIR:h}
else
  DOTFILES_DIR=$DEPLOY_DIR:h
fi

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

# Same contract as required(), but for long-running steps (brew bundle, the
# Homebrew installer) where command substitution's full buffering leaves the
# terminal silent for minutes with no way to tell "working" from "stuck".
# Streams "$@"'s output live instead of capturing it, while still tee-ing to
# a logfile so a FAILED step leaves something concrete behind, and still
# exits on failure like required() does. $pipestatus[1] is "$@"'s own exit
# code, not tee's — checking it explicitly means no shell option needs to
# change just to make a failing piped command detectable.
stream() {
  local desc=$1; shift
  print "$desc..."
  local logfile=$(mktemp)
  "$@" 2>&1 | tee "$logfile"
  local exit_code=$pipestatus[1]
  if (( exit_code == 0 )); then
    print "  ...done"
    rm -f "$logfile"
  else
    print "  FAILED (exit $exit_code) — log: $logfile"
    exit 1
  fi
}

# Function to create required directories
create_directories() {
  setopt local_options err_exit
  zf_mkdir -p $XDG_CONFIG_HOME/{act,bat/themes,direnv,docker,eza,git,htop,ghostty,ripgrep,tealdeer,zsh-patina,homebrew,nvim}
  zf_mkdir -p $XDG_CONFIG_HOME/zellij/{themes,layouts}
  zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh/completions,direnv,bat,tealdeer,git-credential-cache}
  zf_mkdir -p $XDG_DATA_HOME/{nvim,terminfo,direnv,zoxide,go,colima,zsh/plugins}
  zf_mkdir -p $XDG_STATE_HOME/{zsh,less}
  zf_mkdir -p $XDG_RUNTIME_DIR/Homebrew
  zf_mkdir -p $HOME/.claude
  zf_mkdir -pm 700 $XDG_CONFIG_HOME/ssh
  zf_mkdir -p $HOME/.local/bin
}

# Symlink config files
link_configs() {
  setopt local_options err_exit
  # AGENTS.md is the source of truth; CLAUDE.md is a gitignored symlink so Claude
  # Code picks up the same guidance without duplicating it
  zf_ln -sf AGENTS.md $DOTFILES_DIR/CLAUDE.md

  # Claude Code agent config → ~/.claude/rules. Claude Code doesn't fully honor
  # CLAUDE_CONFIG_DIR (daemon/telemetry/auth subsystems hardcode ~/.claude
  # regardless, #134) so config lives at its real default instead of a
  # half-relocated XDG split. Claude Code auto-discovers and loads every *.md
  # under rules/ recursively and unconditionally — no loader file or @import
  # wiring needed. See claude/README.md.
  # Symlinked as one directory so universal/tools/platform (and any gitignored
  # private file dropped inside them) all come along with zero per-file wiring.
  # One-time cleanup of prior layouts (claude/CLAUDE.md + claude/fragments/ from the
  # old loader design; a real claude/rules/ dir of individual symlinks from the
  # per-file-glob design) — safe since deploy fully owns all of these paths.
  rm -f $HOME/.claude/CLAUDE.md
  rm -rf $HOME/.claude/fragments
  rm -rf $HOME/.claude/rules
  zf_ln -sfn $DOTFILES_DIR/claude/rules $HOME/.claude/rules

  # Claude Code subagents → ~/.claude/agents. Same one-directory symlink as
  # rules/ above — every *.md under agents/ is discovered recursively, no per-agent
  # wiring. See claude/README.md § Subagents.
  rm -rf $HOME/.claude/agents
  zf_ln -sfn $DOTFILES_DIR/claude/agents $HOME/.claude/agents

  # Claude Code skills → ~/.claude/skills. Same one-directory symlink as
  # rules/ and agents/ above — every skill's SKILL.md under skills/<name>/ is
  # discovered recursively, no per-skill wiring. See claude/README.md § Skills.
  rm -rf $HOME/.claude/skills
  zf_ln -sfn $DOTFILES_DIR/claude/skills $HOME/.claude/skills

  # Claude Code global settings (telemetry/error-reporting/auto-update opt-outs).
  zf_ln -sf $DOTFILES_DIR/claude/settings.json $HOME/.claude/settings.json

  zf_ln -sf $DOTFILES_DIR/zsh/.zshenv $HOME/.zshenv
  zf_ln -sf $DOTFILES_DIR/zsh-patinaconfig.toml $XDG_CONFIG_HOME/zsh-patina/config.toml
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

  # Backs the `pr`/`new`/`sync`/`squash` aliases above — must be on PATH as
  # bare commands, not just reachable by relative path, since git/config is
  # used from any repo.
  zf_ln -sf $DOTFILES_DIR/scripts/git-pr-link.sh $HOME/.local/bin/git-pr-link
  zf_ln -sf $DOTFILES_DIR/scripts/git-new.sh $HOME/.local/bin/git-new
  zf_ln -sf $DOTFILES_DIR/scripts/git-sync.sh $HOME/.local/bin/git-sync
  zf_ln -sf $DOTFILES_DIR/scripts/git-squash.sh $HOME/.local/bin/git-squash

  # Bootstraps a new Python project from python/ (#129). See py-new.sh.
  zf_ln -sf $DOTFILES_DIR/scripts/py-new.sh $HOME/.local/bin/py-new

  zf_ln -sf $DOTFILES_DIR/ripgreprc $XDG_CONFIG_HOME/ripgrep/config
  zf_ln -sf $DOTFILES_DIR/curlrc $XDG_CONFIG_HOME/curlrc
  zf_ln -sf $DOTFILES_DIR/tealdeerconfig.toml $XDG_CONFIG_HOME/tealdeer/config.toml
  # Pins the runner image `act` uses — see actrc's own comment.
  zf_ln -sf $DOTFILES_DIR/actrc $XDG_CONFIG_HOME/act/actrc

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
    powerlevel10k $HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k
    zsh-autopair  $HOMEBREW_PREFIX/share/zsh-autopair
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

# Registers this repo for git's background maintenance (launchd on macOS),
# which prefetches origin so remote-tracking refs stay current with zero
# effort — `git new`'s fetch becomes an instant no-op. Scoped to this repo;
# run `git maintenance start` by hand in any other repo that wants the same
# background freshness.
enable_git_maintenance() {
  git -C $DOTFILES_DIR maintenance start
}

# Trigger zsh run to download gitstatusd
download_gitstatusd() {
  # CI=1 skips .zshrc's zellij auto-attach block — without it, this
  # non-tty interactive shell hits `exec zellij attach` and hangs forever
  # instead of just running the p10k/gitstatusd bootstrap it's here for.
  CI=1 $SHELL -is <<< ''
}

# Seed deja's suggestion database from existing zsh history. `deja import`
# is *not* idempotent — re-running it double-counts every command already in
# the db (verified: re-importing the same history doubled row count) — so
# this must only ever run once. Guarding on the db file's existence doesn't
# work: `download_gitstatusd` (just above) spawns an interactive shell that
# sources .zshrc, whose `deja init zsh` auto-starts deja's daemon, which
# creates that same db file (empty) on startup — before this step runs.
# A file-existence check would then always see the file already there and
# skip the import, forever, so this uses a marker file this function alone
# controls instead.
import_deja_history() {
  local marker=$XDG_STATE_HOME/deja/.imported
  [[ -f $marker ]] && return
  deja import
  zf_mkdir -p ${marker:h}
  touch $marker
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
# terminfo predates Ghostty. Compiled from the vendored source, same as
# linux/deploy.sh — not extracted from Ghostty.app: the app's location stops
# being predictable once casks may install outside /Applications (#206), and
# the vendored file works before (or without) the cask being installed.
# Tradeoff: the vendored file can lag a newer Ghostty — refresh it when
# Ghostty's terminfo changes. Bare tic, no brewed-ncurses path: macOS's
# system tic compiles this entry identically to brewed tic (verified
# byte-identical via infocmp), so no Homebrew dependency is needed here.
generate_ghostty_terminfo() {
  tic -x -o "$XDG_DATA_HOME/terminfo" "$DOTFILES_DIR/ghostty/xterm-ghostty.terminfo"
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
stream   "Checking for Homebrew"               install_homebrew
stream   "Installing Brewfile packages"        install_brewfile
optional "Installing lefthook hooks"           install_lefthook_hooks
required "Linking zsh plugins"                 link_zsh_plugins
required "Syncing submodules"                  sync_submodules
optional "Enabling git maintenance"            enable_git_maintenance
optional "Building bat theme cache"            build_bat_cache
optional "Downloading gitstatusd for p10k"     download_gitstatusd
optional "Importing zsh history into deja"     import_deja_history
optional "Generating dua/doggo completions"    generate_completions
optional "Refreshing TLDR pages"               refresh_tldr
required "Installing Ghostty terminfo"         generate_ghostty_terminfo
optional "Granting zellij plugin permissions"  grant_zellij_permissions
optional "Setting up Neovim plugins/LSPs"      set_neovim
