#!/usr/bin/env zsh

# Load Zsh modules for managing files
zmodload -m -F zsh/files b:zf_ln b:zf_mkdir

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

DEPLOY_DIR=$(dirname $(realpath $0))

# Anchor to the main checkout via --git-common-dir, not $DEPLOY_DIR: a linked
# worktree is ephemeral, so links made from one dangle once it's removed.
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

# $TMPDIR is macOS's secure, non-persistent per-user dir — what XDG_RUNTIME_DIR wants.
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

# required()'s contract for long steps that would otherwise sit silent —
# see AGENTS.md. $pipestatus[1] is "$@"'s exit code, not tee's.
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

create_directories() {
  setopt local_options err_exit
  zf_mkdir -p $XDG_CONFIG_HOME/{act,aichat,bat/themes,direnv,docker,eza/themes/mocha,eza/themes/latte,git,htop,ghostty,ripgrep,tealdeer,zsh-patina,homebrew,nvim}
  zf_mkdir -p $XDG_CONFIG_HOME/zellij/{themes,layouts}
  zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh/completions,direnv,bat,tealdeer,git-credential-cache}
  zf_mkdir -p $XDG_DATA_HOME/{nvim,terminfo,direnv,zoxide,go,colima,fnm,zsh/plugins}
  zf_mkdir -p $XDG_STATE_HOME/{zsh,less}
  zf_mkdir -p $XDG_RUNTIME_DIR/Homebrew
  zf_mkdir -p $HOME/.claude
  zf_mkdir -pm 700 $XDG_CONFIG_HOME/ssh
  zf_mkdir -p $HOME/.local/bin
}

link_configs() {
  setopt local_options err_exit
  # AGENTS.md is the source of truth; CLAUDE.md is a gitignored symlink so Claude
  # Code picks up the same guidance without duplicating it
  zf_ln -sf AGENTS.md $DOTFILES_DIR/CLAUDE.md

  # → ~/.claude/{rules,agents,skills}, layered from claude/global/ (submodule)
  # plus repo-local exceptions — see claude/README.md § Deployment; ADR-0039.

  # rm first: clears the old loader/per-file layouts; deploy owns all these paths.
  rm -f $HOME/.claude/CLAUDE.md
  rm -rf $HOME/.claude/fragments
  rm -rf $HOME/.claude/rules
  rm -rf $HOME/.claude/agents
  rm -rf $HOME/.claude/skills

  zf_mkdir -p $HOME/.claude/rules
  zf_ln -sfn $DOTFILES_DIR/claude/global/rules/domain $HOME/.claude/rules/domain
  zf_ln -sfn $DOTFILES_DIR/claude/global/rules/tools $HOME/.claude/rules/tools
  zf_ln -sfn $DOTFILES_DIR/claude/global/rules/universal $HOME/.claude/rules/universal

  zf_mkdir -p $HOME/.claude/rules/platform
  zf_ln -sf $DOTFILES_DIR/claude/global/rules/platform/github.md $HOME/.claude/rules/platform/github.md
  zf_ln -sfn $DOTFILES_DIR/claude/rules/platform/private $HOME/.claude/rules/platform/private

  # agents/ moved to claude/global/ entirely (dotfiles#569) — whole-dir symlink.
  zf_ln -sfn $DOTFILES_DIR/claude/global/agents $HOME/.claude/agents

  # verify-nvim-config stays local: it verifies *this* repo's nvim config.
  zf_mkdir -p $HOME/.claude/skills
  for d in $DOTFILES_DIR/claude/global/skills/*(/N); do
    zf_ln -sfn $d $HOME/.claude/skills/$d:t
  done
  zf_ln -sfn $DOTFILES_DIR/claude/skills/verify-nvim-config $HOME/.claude/skills/verify-nvim-config

  # Claude Code global settings (telemetry/error-reporting/auto-update opt-outs).
  zf_ln -sf $DOTFILES_DIR/claude/settings.json $HOME/.claude/settings.json

  zf_ln -sf $DOTFILES_DIR/zsh/.zshenv $HOME/.zshenv

  # Both flavours deployed unconditionally — THEME_MODE selects one at shell-init
  # time, so an appearance flip needs no re-deploy. See ADR-0034.
  zf_ln -sf $DOTFILES_DIR/zsh-patinaconfig-mocha.toml $XDG_CONFIG_HOME/zsh-patina/config-mocha.toml
  zf_ln -sf $DOTFILES_DIR/zsh-patinaconfig-latte.toml $XDG_CONFIG_HOME/zsh-patina/config-latte.toml
  zf_ln -sf $DOTFILES_DIR/theme/eza/themes/mocha/catppuccin-mocha-mauve.yml $XDG_CONFIG_HOME/eza/themes/mocha/theme.yml
  zf_ln -sf $DOTFILES_DIR/theme/eza/themes/latte/catppuccin-latte-mauve.yml $XDG_CONFIG_HOME/eza/themes/latte/theme.yml

  zf_ln -sf $DOTFILES_DIR/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
  zf_ln -sfn $DOTFILES_DIR/nvim/lua $XDG_CONFIG_HOME/nvim/lua
  zf_ln -sf $DOTFILES_DIR/nvim/lazy-lock.json $XDG_CONFIG_HOME/nvim/lazy-lock.json

  zf_ln -sf $DOTFILES_DIR/ghostty/config $XDG_CONFIG_HOME/ghostty/config

  # Per-file, not the whole dir: aichat writes REPL history/sessions into its
  # config dir, and a dir symlink would land them inside the repo (#511).
  zf_ln -sf $DOTFILES_DIR/aichat/config.yaml $XDG_CONFIG_HOME/aichat/config.yaml
  zf_ln -sfn $DOTFILES_DIR/aichat/roles $XDG_CONFIG_HOME/aichat/roles

  zf_ln -sf $DOTFILES_DIR/zellij/config.kdl $XDG_CONFIG_HOME/zellij/config.kdl
  zf_ln -sf $DOTFILES_DIR/zellij/themes/catppuccin.kdl $XDG_CONFIG_HOME/zellij/themes/catppuccin.kdl
  zf_ln -sf $DOTFILES_DIR/zellij/layouts/default.kdl $XDG_CONFIG_HOME/zellij/layouts/default.kdl

  zf_ln -sf $DOTFILES_DIR/htoprc $XDG_CONFIG_HOME/htop/htoprc

  zf_ln -sf $DOTFILES_DIR/batconfig $XDG_CONFIG_HOME/bat/config
  # Both flavours deployed unconditionally — BAT_THEME (zsh/.zshenv) selects
  # by THEME_MODE at invocation time, no re-deploy needed.
  zf_ln -sf $DOTFILES_DIR/theme/bat/themes/"Catppuccin Mocha.tmTheme" $XDG_CONFIG_HOME/bat/themes/"Catppuccin Mocha.tmTheme"
  zf_ln -sf $DOTFILES_DIR/theme/bat/themes/"Catppuccin Latte.tmTheme" $XDG_CONFIG_HOME/bat/themes/"Catppuccin Latte.tmTheme"

  zf_ln -sf $DOTFILES_DIR/git/attributes $XDG_CONFIG_HOME/git/attributes
  zf_ln -sf $DOTFILES_DIR/git/committemplate $XDG_CONFIG_HOME/git/committemplate
  zf_ln -sf $DOTFILES_DIR/git/config $XDG_CONFIG_HOME/git/config
  zf_ln -sf $DOTFILES_DIR/git/ignore $XDG_CONFIG_HOME/git/ignore
  zf_ln -sf $DOTFILES_DIR/theme/delta/catppuccin.gitconfig $XDG_CONFIG_HOME/git/catppuccin.gitconfig

  # Must be on PATH as bare commands, not a relative path: the git/config aliases
  # (`pr`/`new`/`sync`/`squash`) they back run from any repo.
  zf_ln -sf $DOTFILES_DIR/scripts/aichat-pane.sh $HOME/.local/bin/aichat-pane
  zf_ln -sf $DOTFILES_DIR/scripts/git-pr-link.sh $HOME/.local/bin/git-pr-link
  zf_ln -sf $DOTFILES_DIR/scripts/git-new.sh $HOME/.local/bin/git-new
  zf_ln -sf $DOTFILES_DIR/scripts/git-sync.sh $HOME/.local/bin/git-sync
  zf_ln -sf $DOTFILES_DIR/scripts/git-squash.sh $HOME/.local/bin/git-squash

  # On PATH as a bare command so any repo's .envrc can fetch it (#377, ADR-0041).
  # macOS only — the Keychain read it relies on is.
  zf_ln -sf $DOTFILES_DIR/scripts/aws-vended-token.sh $HOME/.local/bin/aws-vended-token

  # Audits infra's elevated Keychain items (infra#167) — macOS only, like
  # everything Keychain-shaped here.
  zf_ln -sf $DOTFILES_DIR/scripts/audit-keychain-gate.sh $HOME/.local/bin/audit-keychain-gate

  # Runs one command as a deliberation agent's machine account (#540) — on
  # PATH so any repo's agent session can call it. macOS only (Keychain).
  zf_ln -sf $DOTFILES_DIR/scripts/agent-gh.sh $HOME/.local/bin/agent-gh

  # Drops the vended GH_TOKEN/GITHUB_TOKEN for infra writes (#613) — on PATH,
  # macOS only like every other GH_TOKEN wrapper here.
  zf_ln -sf $DOTFILES_DIR/scripts/infra-gh.sh $HOME/.local/bin/infra-gh

  # Agent-memory B2 backup (#542) — on PATH so the plist below can invoke it
  # by bare name, no absolute-path templating. macOS only.
  zf_ln -sf $DOTFILES_DIR/scripts/backup-agent-memory.sh $HOME/.local/bin/backup-agent-memory
  zf_mkdir -p $HOME/Library/LaunchAgents
  zf_ln -sf $DOTFILES_DIR/macos/com.carpet-stain.dotfiles.agent-memory-backup.plist $HOME/Library/LaunchAgents/com.carpet-stain.dotfiles.agent-memory-backup.plist

  # Weekly token-usage snapshot (#518) — same on-PATH-by-bare-name shape as
  # the agent-memory backup above, so the plist needs no path templating.
  zf_ln -sf $DOTFILES_DIR/scripts/snapshot-token-usage.sh $HOME/.local/bin/snapshot-token-usage
  zf_ln -sf $DOTFILES_DIR/macos/com.carpet-stain.dotfiles.token-usage-snapshot.plist $HOME/Library/LaunchAgents/com.carpet-stain.dotfiles.token-usage-snapshot.plist

  # direnv auto-sources ~/.config/direnv/lib/*.sh before a repo's .envrc
  # — use_github_token (the shared vended-token bridge, #195) lives here.
  zf_ln -sfn $DOTFILES_DIR/direnv/lib $XDG_CONFIG_HOME/direnv/lib

  zf_ln -sf $DOTFILES_DIR/ripgreprc $XDG_CONFIG_HOME/ripgrep/config
  zf_ln -sf $DOTFILES_DIR/curlrc $XDG_CONFIG_HOME/curlrc
  zf_ln -sf $DOTFILES_DIR/tealdeerconfig.toml $XDG_CONFIG_HOME/tealdeer/config.toml
  # Pins the runner image `act` uses — see actrc's own comment.
  zf_ln -sf $DOTFILES_DIR/actrc $XDG_CONFIG_HOME/act/actrc

  # $DOTFILES_DIR, not $DEPLOY_DIR — a worktree-invoked deploy would otherwise
  # point these links at the ephemeral worktree copy (see the anchor up top).
  zf_ln -sf $DOTFILES_DIR/macos/brew.env $XDG_CONFIG_HOME/homebrew/brew.env

  # Only for ad hoc `brew bundle --file=...` use — install_brewfile always passes
  # an explicit --file, so deploy never reads these back. Tiers: each file's header.
  zf_ln -sf $DOTFILES_DIR/macos/Brewfile.payload $XDG_CONFIG_HOME/homebrew/Brewfile.payload
  zf_ln -sf $DOTFILES_DIR/macos/Brewfile.dev $XDG_CONFIG_HOME/homebrew/Brewfile.dev
  zf_ln -sf $DOTFILES_DIR/macos/Brewfile.personal $XDG_CONFIG_HOME/homebrew/Brewfile.personal

  zf_ln -sf $DOTFILES_DIR/ssh/config $XDG_CONFIG_HOME/ssh/config

  # Machine-local (real hostnames/IPs), deliberately untracked — ssh/config's
  # `Include` needs it to exist, so create once and never overwrite.
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

# $HOME/homebrew is the no-sudo install (#206). Same probe order as
# zsh/.zshenv — keep the two in sync.
brew_bin() {
  local b
  for b in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew} $HOME/homebrew/bin/brew /opt/homebrew/bin/brew; do
    if [[ -x $b ]]; then
      print -r -- $b
      return 0
    fi
  done
  command -v brew
}

# A non-admin user can't sudo into /opt/homebrew, so it gets the untar-anywhere
# install (#206) — cellar-locked formulae then build from source, needing Xcode CLT.
install_homebrew() {
  setopt local_options err_exit pipe_fail
  if [[ -n $(brew_bin) ]]; then
    return 0
  fi
  if dseditgroup -o checkmember -m $USER admin >/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    zf_mkdir -p $HOME/homebrew
    curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C $HOME/homebrew
  fi
}

install_brewfile() {
  setopt local_options err_exit
  local file
  for file in Brewfile.payload Brewfile.dev Brewfile.personal; do
    brew bundle --file=$DEPLOY_DIR/$file
  done
}

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
    # Fail loudly rather than symlink a path that doesn't exist yet — a dangling
    # link surfaces later as an opaque `source` error at shell startup.
    [[ -e $plugin_srcs[$name] ]] || { print "  Missing $name at $plugin_srcs[$name]" >&2; return 1 }
    zf_ln -sf $plugin_srcs[$name] $XDG_DATA_HOME/zsh/plugins/$name
  done
}

sync_submodules() {
  setopt local_options err_exit
  git -C $DOTFILES_DIR submodule sync
  git -C $DOTFILES_DIR submodule update --init --recursive
}

# Background prefetch keeps remote-tracking refs current, so `git new`'s fetch is
# a no-op. Scoped to this repo — run `git maintenance start` by hand in others.
enable_git_maintenance() {
  git -C $DOTFILES_DIR maintenance start
}

# Reload, not just load: launchd errors on an already-loaded label, so
# unload-then-load is what keeps a re-run of deploy.zsh idempotent.
enable_agent_memory_backup() {
  local plist=$HOME/Library/LaunchAgents/com.carpet-stain.dotfiles.agent-memory-backup.plist
  launchctl unload $plist 2>/dev/null || true
  launchctl load -w $plist
}

enable_token_usage_snapshot() {
  local plist=$HOME/Library/LaunchAgents/com.carpet-stain.dotfiles.token-usage-snapshot.plist
  launchctl unload $plist 2>/dev/null || true
  launchctl load -w $plist
}

# Trigger zsh run to download gitstatusd
download_gitstatusd() {
  # CI=1 skips .zshrc's zellij auto-attach — without it this non-tty
  # interactive shell hits `exec zellij attach` and hangs forever.
  CI=1 $SHELL -is <<< ''
}

# Run-once: `deja import` isn't idempotent, and the marker (not the db file)
# is the gate. --file is mandatory — see AGENTS.md for both, and why.
import_deja_history() {
  local marker=$XDG_STATE_HOME/deja/.imported
  [[ -f $marker ]] && return
  deja import --file $XDG_STATE_HOME/zsh/history
  zf_mkdir -p ${marker:h}
  touch $marker
}

# Generate completions for tools with no Homebrew-shipped zsh completion file
generate_completions() {
  dua completions zsh > $XDG_CACHE_HOME/zsh/completions/_dua
  doggo completions zsh > $XDG_CACHE_HOME/zsh/completions/_doggo
}

refresh_tldr() {
  tldr -u
}

# Compiled from the vendored source, not Ghostty.app — the cask's location isn't
# predictable (#206). Refresh the vendored file when Ghostty's terminfo changes.
generate_ghostty_terminfo() {
  tic -x -o "$XDG_DATA_HOME/terminfo" "$DOTFILES_DIR/ghostty/xterm-ghostty.terminfo"
}

# Compiles both vendored flavours — BAT_THEME requests one per invocation
# (ADR-0034), and bat's built-in Catppuccin only exists in recent releases.
build_bat_cache() {
  bat cache --build
}

# zjstatus can't be granted interactively — prompts don't render in the 1-row
# status bar pane it lives in (zellij-org/zellij#4749).
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
  # A headless launch is the install step: Lazy syncs plugins and Mason installs
  # whatever ensure_installed names (see AGENTS.md § Structure & conventions).
  command nvim --headless -c "helptags ALL" -c "qall"
}

# +-------------------+
# | EXECUTE FUNCTIONS |
# +-------------------+

required "Creating required directory tree"    create_directories
required "Linking config files"                link_configs
stream   "Checking for Homebrew"               install_homebrew

# Evaluated here, not inside a runner: the runners execute their step in a
# subshell, so brew's env can't propagate up to the steps below.
BREW_BIN=$(brew_bin) || { print "brew not found after install step" >&2; exit 1 }
eval "$($BREW_BIN shellenv)"

# No-sudo machine (#206): casks go to ~/Applications, but pkg casks (mullvad-vpn)
# still need an admin. Same conditional as zsh/.zshenv — keep the two in sync.
if [[ $HOMEBREW_PREFIX != /opt/homebrew && -z $HOMEBREW_CASK_OPTS ]]; then
  export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
fi

stream   "Installing Brewfile packages"        install_brewfile

# Top level, not a runner: set_neovim's Mason bootstrap needs node on PATH now,
# and a subshell's PATH mutation wouldn't reach it (ADR-0029). No errexit here.
print "Installing fnm-managed Node..."
export FNM_DIR=$XDG_DATA_HOME/fnm # fnm reads this from its own subprocess env; must stay in sync with zsh/.zshenv's FNM_DIR
fnm install --lts && fnm default lts-latest || { print "  FAILED: fnm install/default" >&2; exit 1 }
eval "$(fnm env)"
node --version >/dev/null || { print "  FAILED: fnm-provided node did not resolve on PATH after fnm env" >&2; exit 1 }
print "  ...done"

# The one Go tool with no formula; pinned go install is checksum-verified — see
# ADR-0030. Top-level so set_neovim's headless run finds it and skips a Mason copy.
print "Installing impl (go install)..."
export GOPATH=$XDG_DATA_HOME/go # must match zsh/.zshenv's GOPATH
path=($GOPATH/bin $path)
go install github.com/josharian/impl@v1.5.0 || { print "  FAILED: go install impl" >&2; exit 1 }
print "  ...done"

optional "Installing lefthook hooks"           install_lefthook_hooks
required "Linking zsh plugins"                 link_zsh_plugins
required "Syncing submodules"                  sync_submodules
optional "Enabling git maintenance"            enable_git_maintenance
optional "Scheduling agent-memory backup"      enable_agent_memory_backup
optional "Scheduling token-usage snapshot"     enable_token_usage_snapshot
optional "Building bat theme cache"            build_bat_cache
optional "Downloading gitstatusd for p10k"     download_gitstatusd
optional "Importing zsh history into deja"     import_deja_history
optional "Generating dua/doggo completions"    generate_completions
optional "Refreshing TLDR pages"               refresh_tldr
required "Installing Ghostty terminfo"         generate_ghostty_terminfo
optional "Granting zellij plugin permissions"  grant_zellij_permissions
optional "Setting up Neovim plugins/LSPs"      set_neovim
