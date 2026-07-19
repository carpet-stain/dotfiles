# .zshenv is sourced on all shell invocations: interactive, non-interactive, and scripts.
# Set environment variables, paths, and tool configuration here.
# No output, no tty assumptions — this file runs before everything else.

# +-----------+
# | BOOTSTRAP |
# +-----------+

# Resolve ZDOTDIR from this file's own path so zsh can locate the rest of the config
local homezshenv=$HOME/.zshenv
export ZDOTDIR=$homezshenv:A:h

export DOTFILES=$ZDOTDIR:h

# Prevent zsh from sourcing /etc/zprofile, /etc/zshrc, etc.
unsetopt GLOBAL_RCS

# +---------------+
# | CORE PROGRAMS |
# +---------------+

export EDITOR=nvim
export VISUAL=$EDITOR
export PAGER=less

# col -bx strips groff backspace markup; bat renders with man syntax highlighting
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# less: colors, smart-case search, mouse scroll, quit if output fits one screen
export LESS="--RAW-CONTROL-CHARS --quit-if-one-screen --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4 --mouse --wheel-lines=3"

# Allow less to open non-text files (archives, images, etc.) via lesspipe
export LESSOPEN="|lesspipe.sh %s"

# `< file` pages through $PAGER
export READNULLCMD=$PAGER

# +--------------------+
# | XDG BASE DIRS      |
# +--------------------+

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
if [[ $OSTYPE == darwin* ]]; then
  export XDG_RUNTIME_DIR=$TMPDIR
else
  export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}
fi

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Override tool defaults so they write inside XDG dirs instead of $HOME
export HISTFILE=$XDG_STATE_HOME/zsh/history
export LESSHISTFILE=$XDG_STATE_HOME/less/history
export HTOPRC=$XDG_CONFIG_HOME/htop/htoprc
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config
export TEALDEER_CONFIG_DIR=$XDG_CONFIG_HOME/tealdeer
export TERMINFO=$XDG_DATA_HOME/terminfo
export _ZO_DATA_DIR=$XDG_DATA_HOME/zoxide
export GOPATH=$XDG_DATA_HOME/go
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
# npm resolves logs-dir and its update-notifier stamp relative to cache by
# default (verified: both land under NPM_CONFIG_CACHE, not ~/.npm), so cache
# alone relocates everything npm writes on ordinary use. init-module is the
# one leftover: only touched by the rare `npm init` prompt, and it's a
# config template a user might edit, so it goes under XDG_CONFIG_HOME rather
# than cache.
export NPM_CONFIG_INIT_MODULE=$XDG_CONFIG_HOME/npm/init.js
export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
# Suppress Terminal.app session restore files (~/.zsh_sessions, ~/.bash_sessions)
export SHELL_SESSIONS_DISABLE=1

# +------+
# | PATH |
# +------+

# Enforce uniqueness on path arrays before any additions
typeset -U path fpath manpath

if [[ $OSTYPE == darwin* ]]; then
  # +----------+
  # | HOMEBREW |
  # +----------+

  # Keep Homebrew's cache, logs, and temp under XDG dirs (brew.env can't expand vars)
  export HOMEBREW_CACHE=$XDG_CACHE_HOME/Homebrew
  export HOMEBREW_LOGS=$XDG_STATE_HOME/Homebrew/logs
  export HOMEBREW_TEMP=$XDG_RUNTIME_DIR/Homebrew

  # Colima (Docker runtime for `act`) is macOS-only in this repo — see
  # scripts/act-run.sh. COLIMA_HOME relocates its whole tree (config, VM
  # disk, sockets, logs together — Lima's own maintainers deliberately don't
  # split these, so XDG_CONFIG_HOME's narrower/buggier support isn't worth
  # relying on). No separate LIMA_HOME: Colima nests Lima's home at
  # $COLIMA_HOME/_lima on its own.
  export COLIMA_HOME=$XDG_DATA_HOME/colima

  # Sets HOMEBREW_PREFIX, HOMEBREW_CELLAR, HOMEBREW_REPOSITORY, PATH, MANPATH,
  # INFOPATH, and (guarded, recent Homebrew versions) prepends
  # $HOMEBREW_PREFIX/share/zsh/site-functions to FPATH — formula-shipped zsh
  # completions (git, gh, etc.) reach compinit via this line, not an explicit
  # fpath+= in rc.d/completions.zsh.
  # Probe the prefixes this repo supports — an env-provided HOMEBREW_PREFIX,
  # a no-sudo install at $HOME/homebrew (#206), then the Apple Silicon
  # default. Same order as macos/deploy.zsh's brew_bin — keep the two in
  # sync. No brew found is fine (fresh machine): the loop just falls
  # through, silently, where the old hardcoded eval printed an error.
  for _brew in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew} $HOME/homebrew/bin/brew /opt/homebrew/bin/brew; do
    if [[ -x $_brew ]]; then
      eval $($_brew shellenv)
      break
    fi
  done
  unset _brew

  # A non-default prefix means a no-sudo machine (#206): default casks to
  # the user-writable ~/Applications. A pre-set HOMEBREW_CASK_OPTS wins —
  # set it in the environment to pick another writable dir (e.g.
  # --appdir="/Applications/Corporate Apps"). Only drag-install
  # (.app/binary/font) casks work without sudo — pkg-based casks
  # (mullvad-vpn, in Brewfile.personal, is the only one across all three
  # Brewfiles) still need an admin. Same conditional as macos/deploy.zsh —
  # keep the two in sync.
  if [[ -n $HOMEBREW_PREFIX && $HOMEBREW_PREFIX != /opt/homebrew && -z $HOMEBREW_CASK_OPTS ]]; then
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
  fi

  # Remaining Homebrew opt package binaries and man pages. (N) glob qualifier
  # enables null_glob for just this pattern — NULL_GLOB isn't set yet this early
  # (it's an interactive-only option set later in rc.d/options.zsh), and without
  # it an unmatched glob aborts the rest of .zshenv, e.g. on a fresh machine
  # before `brew bundle` has installed anything.
  for bindir in $HOMEBREW_PREFIX/opt/*/bin(N); do path=($bindir $path); done
  for mandir in $HOMEBREW_PREFIX/opt/*/share/man/man1(N); do manpath=($mandir $manpath); done

  # Prefer GNU coreutils over macOS BSD versions (provides un-prefixed names:
  # sed, tar, etc.) — must come after the opt/*/bin loop above so gnubin wins
  # any name collision.
  for bindir in $HOMEBREW_PREFIX/opt/*/libexec/gnubin(N); do path=($bindir $path); done
  for mandir in $HOMEBREW_PREFIX/opt/*/libexec/gnuman(N); do manpath=($mandir $manpath); done

  # +-----+
  # | FNM |
  # +-----+

  # fnm (ADR-0029) provides the Node actually used for development. Must
  # come after the opt/*/bin loop above: Homebrew still installs a Node
  # transitively (prettier/markdownlint-cli2 both depend on it), which that
  # loop would otherwise put on PATH first — fnm's eval below has to win the
  # ordering, not just exist. Guarded, not truly unconditional (a fresh
  # machine has no fnm yet, and .zshenv line 3 forbids output), matching the
  # direnv block's shape below rather than the looser wording that shape
  # implies.
  export FNM_DIR=$XDG_DATA_HOME/fnm # must stay in sync with macos/deploy.zsh's FNM_DIR
  if (( ${+commands[fnm]} )); then
    eval "$(fnm env)"
  fi
fi

# User-local binaries and scripts. Prepend (not append) so a user binary
# shadows a same-named one from the inherited system PATH — matching the
# Homebrew/gnubin prepend idiom above. Since these run last, they end up
# ahead of the Homebrew block too: user ~/.local/bin now wins over Homebrew
# for a same-named binary, an intentional side effect of "last prepend wins
# the front" (see git history for #199's before/after verification).
path=($HOME/.local/bin $path)
path=($GOPATH/bin $path)

# Custom zsh functions and completion definitions
fpath+=$ZDOTDIR/fpath

# +--------+
# | DIRENV |
# +--------+

# direnv's own hook (zsh/.zshrc) only fires for interactive shells — without
# this, a script/cron/agent shell never loads .envrc's GH_TOKEN and `gh`
# silently falls back to a broader keyring session (#160). Non-interactive
# shells get stderr silenced: each is a fresh process, so direnv would log
# "loading ~/.envrc" on every single invocation.
if (( ${+commands[direnv]} )); then
  if [[ -o interactive ]]; then
    emulate zsh -c "$(direnv export zsh)"
  else
    emulate zsh -c "$(direnv export zsh 2>/dev/null)"
  fi
fi

# +-----------+
# | LS COLORS |
# +-----------+

# Generated by `vivid generate catppuccin-mocha`
source $ZDOTDIR/env.d/ls_colors.zsh

# +-----+
# | EZA |
# +-----+

# Shared flag set used by the ls alias and FZF_ALT_C_COMMAND in env.d/fzf.zsh
export EZACMD="eza --color=always --icons=always --group-directories-first -a --classify=auto --dereference"

# +-----------+
# | CLIPBOARD |
# +-----------+

# Clipboard command varies by platform: pbcopy on macOS, wl-copy under a
# Wayland session, xclip on X11. Defined once here and reused by the fzf
# Ctrl+Y binds in env.d/fzf.zsh and the 'C' global alias in rc.d/aliases.zsh.
if [[ $OSTYPE == darwin* ]]; then
  export CLIPBOARD_COPY="pbcopy"
elif [[ -n $WAYLAND_DISPLAY ]]; then
  export CLIPBOARD_COPY="wl-copy"
else
  export CLIPBOARD_COPY="xclip -selection clipboard"
fi

# +-----+
# | FZF |
# +-----+

source $ZDOTDIR/env.d/fzf.zsh
