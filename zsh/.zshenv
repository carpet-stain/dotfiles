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
  # A systemd-less environment never gets /run/user/<uid> and can't create it;
  # zsh-patina's daemon fails EACCES there — see #443.
  [[ -w $XDG_RUNTIME_DIR ]] || export XDG_RUNTIME_DIR=$XDG_STATE_HOME/xdg-runtime
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
# Cache alone relocates everything npm writes on ordinary use (logs-dir and the
# update-notifier stamp derive from it); init.js is a user-editable template.
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

  # Relocates Colima's whole tree at once, and no LIMA_HOME is needed —
  # see scripts/act-run.sh's header for why both are deliberate.
  export COLIMA_HOME=$XDG_DATA_HOME/colima

  # Formula zsh completions reach compinit via this line's fpath prepend, not
  # rc.d/completions.zsh. Prefix order must match deploy.zsh's brew_bin (#206).
  for _brew in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew} $HOME/homebrew/bin/brew /opt/homebrew/bin/brew; do
    if [[ -x $_brew ]]; then
      eval $($_brew shellenv)
      break
    fi
  done
  unset _brew

  # No-sudo machine (#206): only drag-install casks work, pkg-based ones still
  # need an admin. Same conditional as macos/deploy.zsh — keep the two in sync.
  if [[ -n $HOMEBREW_PREFIX && $HOMEBREW_PREFIX != /opt/homebrew && -z $HOMEBREW_CASK_OPTS ]]; then
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
  fi

  # (N) is load-bearing: NULL_GLOB isn't set this early (interactive-only, in
  # rc.d/options.zsh) and an unmatched glob aborts the rest of .zshenv.
  for bindir in $HOMEBREW_PREFIX/opt/*/bin(N); do path=($bindir $path); done
  for mandir in $HOMEBREW_PREFIX/opt/*/share/man/man1(N); do manpath=($mandir $manpath); done

  # GNU coreutils under un-prefixed names (sed, tar) — must come after the
  # opt/*/bin loop above so gnubin wins any name collision.
  for bindir in $HOMEBREW_PREFIX/opt/*/libexec/gnubin(N); do path=($bindir $path); done
  for mandir in $HOMEBREW_PREFIX/opt/*/libexec/gnuman(N); do manpath=($mandir $manpath); done

  # +-----+
  # | FNM |
  # +-----+

  # Must come after the opt/*/bin loop above or Homebrew's transitive Node wins
  # PATH (ADR-0029). Guarded: a fresh machine has no fnm and can't print.
  export FNM_DIR=$XDG_DATA_HOME/fnm # must stay in sync with macos/deploy.zsh's FNM_DIR
  if (( ${+commands[fnm]} )); then
    eval "$(fnm env)"
  fi
fi

# Prepended last, so ~/.local/bin also wins over Homebrew for a same-named
# binary — intentional, not a side effect (#199).
path=($HOME/.local/bin $path)
path=($GOPATH/bin $path)

# Custom zsh functions and completion definitions
fpath+=$ZDOTDIR/fpath

# +--------+
# | DIRENV |
# +--------+

# Eager export so non-interactive shells get .envrc's GH_TOKEN too — the hook
# in .zshrc only fires interactively (#160; see AGENTS.md "Credentials").
if (( ${+commands[direnv]} )); then
  if [[ -o interactive ]]; then
    emulate zsh -c "$(direnv export zsh)"
  else
    emulate zsh -c "$(direnv export zsh 2>/dev/null)"
  fi
fi

# +------------+
# | THEME MODE |
# +------------+

# AppleInterfaceStyle exists only in dark mode, so a nonzero read means light.
# Single derivation every theme surface below reads — see ADR-0034.
if [[ $OSTYPE == darwin* ]]; then
  if defaults read -g AppleInterfaceStyle &>/dev/null; then
    export THEME_MODE=dark
  else
    export THEME_MODE=light
  fi
else
  export THEME_MODE=dark
fi

# +-----------+
# | LS COLORS |
# +-----------+

# Mode-selected in env.d/ls_colors.zsh — generated by `vivid generate catppuccin-<mocha|latte>`
source $ZDOTDIR/env.d/ls_colors.zsh

# +-----+
# | EZA |
# +-----+

# Shared flag set used by the ls alias and FZF_ALT_C_COMMAND in env.d/fzf.zsh
export EZACMD="eza --color=always --icons=always --group-directories-first -a --classify=auto --dereference"

# eza has no color-override env var, so mode selection points EZA_CONFIG_DIR at
# one of two theme dirs deploy pre-populates — see ADR-0034.
if [[ $THEME_MODE == light ]]; then
  export EZA_CONFIG_DIR=$XDG_CONFIG_HOME/eza/themes/latte
else
  export EZA_CONFIG_DIR=$XDG_CONFIG_HOME/eza/themes/mocha
fi

# +-----+
# | BAT |
# +-----+

# BAT_THEME, not BAT_THEME_LIGHT/DARK — those trigger bat's own OSC-11 query,
# rejected in ADR-0034.
if [[ $THEME_MODE == light ]]; then
  export BAT_THEME="Catppuccin Latte"
else
  export BAT_THEME="Catppuccin Mocha"
fi

# +-------+
# | DELTA |
# +-------+

# DELTA_FEATURES alone activates the catppuccin sections git/config includes —
# no [delta].features key needed. See ADR-0034.
if [[ $THEME_MODE == light ]]; then
  export DELTA_FEATURES="interactive catppuccin-latte"
else
  export DELTA_FEATURES="interactive catppuccin-mocha"
fi

# +-----------+
# | CLIPBOARD |
# +-----------+

# Consumed by the fzf Ctrl+Y binds in env.d/fzf.zsh and the 'C' global alias in
# rc.d/aliases.zsh.
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
