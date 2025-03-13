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
export PAGER=less
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export LESS="--RAW-CONTROL-CHARS --quit-if-one-screen --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4 --mouse --wheel-lines=3"
export LESSOPEN="|lesspipe.sh %s"
export READNULLCMD=$PAGER
export EZACMD="eza --color=always --icons --group-directories-first -a --classify=auto --dereference"
export FORGIT_FZF_DEFAULT_OPTS="--layout reverse"

# ls colors
source $ZDOTDIR/env.d/ls_colors.zsh

# XDG basedir spec compliance
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_RUNTIME_DIR=$TMPDIR

# XDG-Compliance
export HTOPRC=$XDG_CONFIG_HOME/htop/htoprc
export LESSHISTFILE=$XDG_DATA_HOME/lesshst
export HISTFILE=$XDG_STATE_HOME/zsh/history
export TEALDEER_CONFIG_DIR=$XDG_CONFIG_HOME/tealdeer
export ELECTRUMDIR=$XDG_DATA_HOME/electrum
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=$TERMINFO
export TMUX_TMPDIR=$XDG_RUNTIME_DIR/tmux
export _ZO_DATA_DIR=$XDG_DATA_HOME/zoxide

# +-----+
# | FZF |
# +-----+

export FZF_DEFAULT_COMMAND="rg --files"

export FZF_DEFAULT_OPTS="
  --color bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color selected-bg:#45475a
  --color border:#313244,label:#cdd6f4
  --color header:italic
  --info right
  --prompt ' : '
  --pointer ''
  --marker '✓'
  --ansi
  --tmux 90%"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --border rounded
  --border-label ' 󱉭 $(pwd)/ '
  --border-label-pos center
  --preview 'bat {}'
  --preview-window 'right:65%'
  --header '📌 ⌃ O open | ⌃ Y copy | ⌃ E edit'
  --bind 'ctrl-o:execute(open -R {} &)'
  --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
  --bind 'ctrl-e:become($EDITOR {1} +{2} < /dev/tty > /dev/tty)'
  --select-1 --exit-0"

export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'Press CTRL-Y to copy command into clipboard'"

export FZF_ALT_C_OPTS="--ansi --preview '$EZACMD --tree --level=3 {}'"

# +-------+
# | PATHS |
# +-------+

# Initialize path
path+=$HOME/.local/bin

# Add custom functions and completions
fpath+=(${ZDOTDIR}/fpath)

# Set Homebrew shell environment
eval $($HOME/tiktok/homebrew/bin/brew shellenv)

# Enable gnu version of utilities on macOS
for bindir in $HOMEBREW_PREFIX/opt/*/libexec/gnubin; do path=($bindir $path); done
for bindir in $HOMEBREW_PREFIX/opt/*/bin; do path=($bindir $path); done
for mandir in $HOMEBREW_PREFIX/opt/*/libexec/gnuman; do manpath=($mandir $manpath); done
for mandir in $HOMEBREW_PREFIX/opt/*/share/man/man1; do manpath=($mandir $manpath); done
