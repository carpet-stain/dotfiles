# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.

# Determine own path
local homezshenv=$HOME/.zshenv
# Set ZDOTDIR to the directory containing this .zshenv file.
# This is the core of the "zero home presence" setup.
# :A - Resolves to an absolute, real path (like realpath)
# :h - Resolves to the 'head' (directory name) of the path
export ZDOTDIR=$homezshenv:A:h

# DOTFILES dir is parent to ZDOTDIR
# Assumes ZDOTDIR is a subdirectory of the main dotfiles repo (e.g., .../dotfiles/zsh)
export DOTFILES=$ZDOTDIR:h

# Disable global zsh configuration
# This prevents Zsh from sourcing global files like /etc/zshrc.
# It ensures this configuration is the *only* one that loads, for full control.
unsetopt GLOBAL_RCS

#  ╭──────────╮
#  │  EXPORT  │
#  ╰──────────╯

export EDITOR=nvim
export VISUAL=$EDITOR
export PAGER=less
# Define a MANPAGER that pipes man pages through 'bat' for syntax highlighting.
# The 'sed' commands are crucial:
# 1. `s/\\x1B\[[0-9;]*m//g` - Strips all ANSI color/style escape codes.
# 2. `s/.\\x08//g` - Strips backspace characters (used by 'man' for bolding/overstriking).
# This provides 'bat' with a "clean" text stream to re-format.
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export LESS="--RAW-CONTROL-CHARS --quit-if-one-screen --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4 --mouse --wheel-lines=3"
export LESSOPEN="|lesspipe.sh %s"
export READNULLCMD=$PAGER
# Define a base command for 'eza' in a variable for easy reuse in aliases/scripts.
export EZACMD="eza --color=always --icons=always --group-directories-first -a --classify=auto --dereference"

# Don't indicate virtualenv in pyenv, indication is done in p10k
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ls colors
source $ZDOTDIR/env.d/ls_colors.zsh

# XDG basedir spec compliance
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_RUNTIME_DIR=$TMPDIR

# XDG-Compliance
# Point all relevant tools to their new XDG-compliant config/data paths.
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
export PYENV_ROOT=$XDG_DATA_HOME/pyenv

# +-----+
# | FZF |
# +-----+

# Use 'ripgrep' as the default file-finder for FZF; it's much faster than 'find'.
export FZF_DEFAULT_COMMAND="rg --files"
export FZF_DEFAULT_OPTS="
  --color bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color selected-bg:#45475a
  --color border:#313244,label:#cdd6f4
  --color header:italic
  --border rounded
  --border-label-pos center
  --layout reverse
  --info right
  --prompt ' : '
  --pointer ''
  --marker '✓'
  --preview-window 'right:65%'
  --ansi
  --tmux 90%" # Set fzf to take 90% of the screen when in tmux

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

# 'become' replaces the fzf process with the new command.
# '{+1}' is fzf syntax for 'all selected items, starting from the first'.
export FZF_CTRL_T_OPTS="
  --border-label '  File Search '
  --preview 'bat {}'
  --header '📌 ⌃O to Open | ⌃Y to Copy | ⌃E to Edit'
  --bind 'ctrl-o:become(open -R {})'
  --bind 'ctrl-y:become(echo -n {} | pbcopy)'
  --bind 'ctrl-e:become(tmux new-window $EDITOR -p {+1})'
  --select-1 --exit-0" # --select-1: select one item / --exit-0: exit on selection

# For history, the fzf line is "INDEX TIMESTAMP COMMAND".
# '{2..}' is fzf syntax to select all fields *from the second one onwards*,
# which correctly grabs just the command.
export FZF_CTRL_R_OPTS="
  --border-label ' 󰋚 Command History '
  --bind 'ctrl-y:become(echo -n {2..} | pbcopy)'
  --header '📌 ⌃Y to Copy'"

# Use 'fd' (find directory) for Alt-C. 
# -t d: Find directories only
# -H:   Search hidden directories (like .config)
# -E:   Exclude .git to keep it clean
export FZF_ALT_C_COMMAND="fd -t d -H -E .git"

export FZF_ALT_C_OPTS="
  --border-label '   Directory Explorer '
  --preview '$EZACMD --tree --level=2 -I .git {}'"

# +-------+
# | PATHS |
# +-------+

# Initialize path
path+=$HOME/.local/bin

# Add pyenv to the shell
# Prepend the pyenv shims directory to the path.
path=($PYENV_ROOT/bin $path)

# Add custom functions and completions
# 'fpath' is Zsh's path for autoloadable functions, similar to 'path' for binaries.
fpath+=$ZDOTDIR/fpath

# Set Homebrew shell environment using the custom installation path.
# This is required because 'brew' is not in the default system PATH.
eval "$($HOME/tiktok/homebrew/bin/brew shellenv)"

# Enable gnu version of utilities on macOS
# This is the magic loop to prioritize Homebrew's GNU utilities (like gsed, gtar).
# It adds the 'gnubin' directory from *all* keg-only packages to the *front* of the PATH.
for bindir in $HOMEBREW_PREFIX/opt/*/libexec/gnubin; do path=($bindir $path); done
# Do the same for the man pages.
for mandir in $HOMEBREW_PREFIX/opt/*/libexec/gnuman; do manpath=($mandir $manpath); done
for mandir in $HOMEBREW_PREFIX/opt/*/share/man/man1; do manpath=($mandir $manpath); done