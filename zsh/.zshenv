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

#  ╭──────────╮
#  │  EXPORT  │
#  ╰──────────╯

export EDITOR=nvim
export VISUAL=$EDITOR
export NVIM_APPNAME=dotfiles/nvim
export PAGER=less
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export LESS="--RAW-CONTROL-CHARS --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4 --mouse --wheel-lines=3"
export LESSOPEN='lessopen.sh %s'
export LESS_ADVANCED_PREPROCESSOR=1
export READNULLCMD=$PAGER

# eza colors
source "$ZDOTDIR/env.d/ls_colors.zsh"

# XDG basedir spec compliance
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_RUNTIME_DIR=$TMPDIR:-/tmp/runtime-$USER

# XDG-Compliance
export HTOPRC=$XDG_CONFIG_HOME/htop/htoprc
export LESSHISTFILE=$XDG_DATA_HOME/lesshst
export HISTFILE=$XDG_STATE_HOME/zsh/history
export TEALDEER_CONFIG_DIR=$XDG_CONFIG_HOME/tealdeer
export HTTPIE_CONFIG_DIR=$XDG_CONFIG_HOME/httpie
export ELECTRUMDIR=$XDG_DATA_HOME/electrum
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=$TERMINFO

export HOMEBREW_PREFIX=/opt/homebrew

# +-----+
# | FZF |
# +-----+

export FZF_DEFAULT_COMMAND="rg --files"
export FZF_DEFAULT_OPTS_FILE=$XDG_CONFIG_HOME/fzfrc

# Preview file content using bat
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat {}'
  --prompt ' : '
  --pointer ''
  --marker '✓'
  --header '📌 ⌘ O open | ⌥ S sort | ⌘ Y copy | ⌘ E edit'
  --bind 'ctrl-o:execute(open {} >/dev/null 2>&1 &)'
  --bind 'alt-s:toggle-sort'
  --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
  --bind 'ctrl-e:execute($EDITOR {} &>/dev/null &)'
  --color header:italic
  --select-1 --exit-0"

# ? to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
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

autoload -z evalcache
evalcache brew shellenv

# Enable gnu version of utilities on macOS
for bindir in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do export PATH=$bindir:$PATH; done
for bindir in ${HOMEBREW_PREFIX}/opt/*/bin; do export PATH=$bindir:$PATH; done
for mandir in ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman; do export MANPATH=$mandir:$MANPATH; done
for mandir in ${HOMEBREW_PREFIX}/opt/*/share/man/man1; do export MANPATH=$mandir:$MANPATH; done

# Enable local binaries and man pages
path=($HOME/.local/bin $path)
MANPATH=$XDG_DATA_HOME/man:$MANPATH
