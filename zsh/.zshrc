# .zshrc is sourced for interactive shells.
# It's the main "command center" for your shell, loading plugins,
# setting options, and defining aliases.

# +------+
# | TMUX |
# +------+

# Automatically start or attach to a tmux session on shell start.
# This entire block is guarded to prevent it from running in situations
# where you don't want it (like over SSH or when running as root).
#
# Guard conditions:
#   ! -v SSH_TTY:  Ensures this does *not* run in an SSH session.
#   $EUID != 0:    Ensures this does *not* run when root or using sudo.
if [[ ! -v SSH_TTY && $EUID != 0 ]]; then
  # `pgrep -x tmux` checks for an *exact* process match for "tmux".
  if ! pgrep -x tmux &> /dev/null; then
    print "Tmux is not running, starting a new session..."
    # `exec` replaces the current zsh process with tmux.
    # When you quit tmux, the shell/terminal will also close.
    exec tmux -f $DOTFILES/tmux/tmux.conf new-session -s personal

  # Tmux sets the $TMUX variable for all shells running *inside* it.
  # `[[ -z $TMUX ]]` checks if that variable is empty.
  elif [[ -z $TMUX ]]; then
    # Try to attach to the last-used session.
    # If that fails (||), create a new 'personal' session instead.
    exec tmux attach || exec tmux -f $DOTFILES/tmux/tmux.conf new-session -s personal
  fi
fi

# +---------------------+
# | P10K INSTANT PROMPT |
# +---------------------+

# This is the P10k+direnv integration, which must be in two parts.
# PART 1: Load direnv *environment variables* before P10k instant prompt.
# `emulate zsh` runs the command in a clean zsh state, ignoring local aliases/options.
emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#
# Check if the instant-prompt cache file exists and is readable (-r).
# The `${(%):-%n}` is a Zsh-specific, robust way to get the $USERNAME.
# `(%):-` tells Zsh to apply prompt-style expansion to `%n` (username).
# This is safer than just `$USER` in all edge cases (e.g., sudo).
if [[ -r $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh
fi

# PART 2: Load the direnv *hook* (which runs on `cd`) *after* the instant prompt.
# This prevents the direnv hook setup from slowing down the prompt.
emulate zsh -c "$(direnv hook zsh)"

# +---------+
# | OPTIONS |
# +---------+

# Load all custom shell options (setopt, unsetopt).
source $ZDOTDIR/rc.d/options.zsh

# +---------+
# | WIDGETS |
# +---------+

# Load all custom Zle (Zsh Line Editor) widgets and hooks.
source $ZDOTDIR/rc.d/widgets.zsh

# +--------------+
# | KEY BINDINGS |
# +--------------+

# Bind keys to the widgets loaded above.
source $ZDOTDIR/rc.d/key-bindings.zsh

# +---------+
# | ALIASES |
# +---------+

# Load all personal aliases.
source $ZDOTDIR/rc.d/aliases.zsh

# +---------------+
# | POWERLEVEL10K |
# +---------------+

# Load the P10k theme configuration.
source $ZDOTDIR/rc.d/powerlevel10k.zsh

# +-------------+
# | COMPLETIONS |
# +-------------+

# Initialize the Zsh completion system (`compinit`).
# Compinit is called here.
source $ZDOTDIR/rc.d/completions.zsh

# +-------+
# | PYENV |
# +-------+

# Initialize pyenv shims and completions for interactive shells.
eval "$(pyenv init -)"

# +--------+
# | ZOXIDE |
# +--------+

# The init script is smart enough to also set up completions
# that will be picked up by compinit later.
eval "$(zoxide init zsh)"

# +-----+
# | FZF |
# +-----+

# Source Homebrew-installed fzf completions and keybindings (Ctrl-T, Ctrl-R, Alt-C).
source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh

# +---------+
# | FZF-TAB |
# +---------+

# Load fzf-tab configuration, which replaces Zsh's default completion menu.
source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

# Source the autopair plugin (for auto-closing quotes, brackets, etc.).
source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh

# +--------------------+
# | ZSH-AUTOGUESSTIONS |
# +--------------------+

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Set the suggestion strategy.
# 1. 'history': First, try to find a suggestion from shell history.
# 2. 'completion': If no history match, try to generate a suggestion
#                  from the Zsh completion engine (e.g., suggest a filename).
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Clear the current suggestion when any of these widgets are triggered.
# This prevents suggestions from "sticking" when you paste, start a new
# command, or use the custom `_zsh-dot` widget.
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste new-command _zsh-dot)

# +------------------------------+
# | ZSH-FAST-SYNTAX-HIGHLIGHTING |
# +------------------------------+

# This is a compatibility fix for a known issue where the 'whatis'
# command conflicts with an internal variable (`THEFD`) used by
# zsh-fast-syntax-highlighting (FSH) during its analysis.

# This function wrapper checks:
# 1. `[[ -v THEFD ]]`: Is the `THEFD` variable set (i.e., is FSH running)?
# 2. `if ...; then :;`: If YES, do nothing (the `:` command).
# 3. `else command whatis $@`: If NO, run the *real* `whatis` command.
function whatis() { if [[ -v THEFD ]]; then :; else command whatis $@; fi; }

source $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# This is a final cleanup step.
# `typeset -U` forces an array to only contain Unique values.
typeset -U path fpath manpath