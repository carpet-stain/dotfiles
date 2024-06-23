# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.

# Determine own path
local homezshenv=$HOME/.zshenv
export ZDOTDIR=$homezshenv:A:h

# DOTFILES dir is parent to ZDOTDIR
export DOTFILES=$ZDOTDIR:h

# Disable global zsh configuration
unsetopt GLOBAL_RCS

# Load zsh/files module to provide some builtins for file modifications
# This is used in fpath custom functions
zmodload -F -m zsh/files b:zf_\*

#  ╭──────────╮
#  │  EXPORT  │
#  ╰──────────╯

# Prefered editor and pager
export VISUAL=nvim
export EDITOR=nvim
export NVIM_APPNAME=dotfiles/nvim
export PAGER=less
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export LESS="--RAW-CONTROL-CHARS --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4"
export READNULLCMD=$PAGER

# XDG basedir spec compliance
if [[ ! -v XDG_CONFIG_HOME ]]; then
    export XDG_CONFIG_HOME=$HOME/.config
fi
if [[ ! -v XDG_CACHE_HOME ]]; then
    export XDG_CACHE_HOME=$HOME/.cache
fi
if [[ ! -v XDG_DATA_HOME ]]; then
    export XDG_DATA_HOME=$HOME/.local/share
fi
if [[ ! -v XDG_STATE_HOME ]]; then
    export XDG_STATE_HOME=$HOME/.local/state
fi
if [[ ! -v XDG_RUNTIME_DIR ]]; then
    export XDG_RUNTIME_DIR=$TMPDIR:-/tmp/runtime-$USER
fi

# XDG-Compliance
export LESSHISTFILE=$XDG_DATA_HOME/lesshst
export HISTFILE=$XDG_STATE_HOME/zsh/history
export TEALDEER_CONFIG_DIR=$XDG_CONFIG_HOME/tealdeer
export HTTPIE_CONFIG_DIR=$XDG_CONFIG_HOME/httpie
export ELECTRUMDIR=$XDG_DATA_HOME/electrum
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=$TERMINFO_DIRS:$TERMINFO:/usr/share/terminfo
export GOPATH=$XDG_DATA_HOME/go

export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_UPGRADE_GREEDY=1
export HOMEBREW_NO_AUTO_UPDATE=1

export LESSOPEN='lessopen.sh %s'
export LESS_ADVANCED_PREPROCESSOR=1

export BAT_THEME="Catppuccin Mocha"

# fzf
export FZF_DEFAULT_COMMAND="rg --files"

# Catppuccin-mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--ansi \
--height 70% \
--tmux 70%"

# Preview file content using bat
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="
  --preview 'bat {}'
  --color header:italic
  --select-1 --exit-0"

# ? to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Print tree structure in the preview window
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# +-------+
# | PATHS |
# +-------+

# Add custom functions and completions
fpath=($ZDOTDIR/fpath $fpath)

# Initialize path
path=($HOMEBREW_PREFIX/{,s}bin $path)

# Enable man pages
MANPATH=$XDG_DATA_HOME/man:$MANPATH

# Enable gnu version of utilities on macOS
for gnuutil in coreutils gnu-sed gnu-tar; do
    if [[ -d $HOMEBREW_PREFIX/opt/$gnuutil/libexec/gnubin ]]; then
        path=($HOMEBREW_PREFIX/opt/$gnuutil/libexec/gnubin $path)
    fi
    if [[ -d $HOMEBREW_PREFIX/opt/$gnuutil/libexec/gnuman ]]; then
        MANPATH=$HOMEBREW_PREFIX/opt/$gnuutil/libexec/gnuman:$MANPATH
    fi
done
