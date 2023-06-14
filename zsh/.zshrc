# +---------------------+
# | P10K INSTANT PROMPT |
# +---------------------+

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh
fi

# +------------+
# | NAVIGATION |
# +------------+

setopt AUTO_CD          # if the command is directory and cannot be executed, perform cd to this directory
setopt AUTO_PUSHD       # Make cd push the old directory onto the directory stack
setopt PUSHD_SILENT     # Do not print the directory stack after pushd or popd.
setopt CORRECT_ALL      # try to correct the spelling of all arguments in a line
setopt CDABLE_VARS      # Change directory to a path stored in a variable.

# +---------+
# | HISTORY |
# +---------+

setopt APPEND_HISTORY            # history appends to existing file
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt HIST_REDUCE_BLANKS        # trim multiple insignificant blanks in history

HISTFILE=$XDG_STATE_HOME/zsh/history
HISTSIZE=1000000
SAVEHIST=1000000

# History: Use standard ISO 8601 timestamp.
#   %F is equivalent to %Y-%m-%d
#   %T is equivalent to %H:%M:%S (24-hours format)
HISTTIMEFORMAT='[%F %T]'

setopt NO_FLOW_CONTROL           # disable stupid annoying keys
setopt MULTIOS                   # allows multiple input and output redirections
setopt CLOBBER                   # allow > redirection to truncate existing files
setopt BRACE_CCL                 # allow brace character class list expansion
setopt NO_BEEP                   # do not beep on errors
setopt NO_NOMATCH                # try to avoid the 'zsh: no matches found...'
setopt INTERACTIVE_COMMENTS      # allow use of comments in interactive code
setopt AUTO_PARAM_SLASH          # complete folders with / at end
setopt LIST_TYPES                # mark type of completion suggestions
setopt HASH_LIST_ALL             # whenever a command completion is attempted, make sure the entire command path is hashed first
setopt COMPLETE_IN_WORD          # allow completion from within a word/phrase
setopt ALWAYS_TO_END             # move cursor to the end of a completed word
setopt LONG_LIST_JOBS            # display PID when suspending processes as well
setopt AUTO_RESUME               # attempt to resume existing job before creating a new process
setopt NOTIFY                    # report status of background jobs immediately
setopt NO_HUP                    # Don't send SIGHUP to background processes when the shell exits
setopt PUSHD_IGNORE_DUPS         # don't push the same dir twice
setopt NO_GLOB_DOTS              # * shouldn't match dotfiles. ever.
setopt NO_SH_WORD_SPLIT          # use zsh style word splitting
setopt INTERACTIVE_COMMENTS      # enable interactive comments
unsetopt RM_STAR_SILENT          # notify when rm is running with *
setopt RM_STAR_WAIT              # wait for 10 seconds confirmation when running rm with *

# a bit fancier than default
PROMPT_EOL_MARK='%K{red} %k'

# +----------+
# | AUTOLOAD |
# +----------+

# Initialize colors
autoload -Uz colors
colors

# Ctrl+W stops on path delimiters
autoload -U select-word-style
select-word-style bash

# Enable run-help module

autoload -Uz run-help

# enable url-quote-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# enable bracketed paste
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# Use default provided history search widgets
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search

# Custom personal functions
# Don't use -U as we need aliases here
autoload -z bag evalcache compdefcache man tat

# +--------------+
# | Key Bindings |
# +--------------+

source $ZDOTDIR/rc.d/keybindings.zsh

# +---------------+
# | POWERLEVEL10K |
# +---------------+

source $ZDOTDIR/rc.d/powerlevel10k.zsh

# +---------+
# | ALIASES |
# +---------+

source $ZDOTDIR/rc.d/aliases.zsh

# +----------+
# | LESSPIPE |
# +----------+

# Make less more friendly
export LESSOPEN='| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-'
export LESS_ADVANCED_PREPROCESSOR=1

# +-------------+
# | COMPLETIONS |
# +-------------+

# Compinit is called here
source $ZDOTDIR/rc.d/completions.zsh

# +--------+
# | ZOXIDE |
# +--------+

# Set up zoxide
eval "$(zoxide init zsh)"

# +-----+
# | FZF |
# +-----+

export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden --color=always'
export FZF_DEFAULT_OPTS="--ansi"
export FZF_TMUX=1
export FZF_TMUX_OPTS='-p80%,60%'

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --select-1 --exit-0
"

# ? to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind '?:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Print tree structure in the preview window
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# Auto-completion
source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh

# Key bindings
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh

# +---------+
# | FZF-TAB |
# +---------+

# Use fzf for tab completions
source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh
source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

[[ -e $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh ]] && 
    source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh

# +------------------------------+
# | ZSH-FAST-SYNTAX-HIGHLIGHTING |
# +------------------------------+

# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis $@; fi; }

# syntax-highlighting plugin
[[ -e $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] && 
    source $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# +----------+
# | ZSH-ABBR |
# +----------+

ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/plugins/abbreviations-store
[[ -e $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh ]] && 
    source $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh &&
    export MANPATH=$HOMEBREW_PREFIX/opt/zsh-abbr/share/man:$MANPATH

# +--------------------+
# | ZSH-AUTOGUESSTIONS |
# +--------------------+

# Don't rebind widgets by autosuggestion, it's already sourced pretty late
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Enable experimental completion suggestions, if `history` returns nothing
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Ignore suggestions for abbreviations
ZSH_AUTOSUGGEST_HISTORY_IGNORE=${(j:|:)${(Qk)ABBR_REGULAR_USER_ABBREVIATIONS}}
ZSH_AUTOSUGGEST_COMPLETION_IGNORE=$ZSH_AUTOSUGGEST_HISTORY_IGNORE

# Autosuggestion plugin
[[ -e $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Need to clear up-line and down-line otherwise auto-auggestions will break
# https://github.com/zsh-users/zsh-autosuggestions/issues/619
# Clear suggestions after paste
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(up-line-or-beginning-search down-line-or-beginning-search bracketed-paste)

# +-----------+
# | GPG-AGENT |
# +-----------+

# remind gpg-agent to update current tty before running git
if pgrep -u $EUID gpg-agent &>/dev/null; then
    function _preexec_gpg-agent-update-tty {
        if [[ $1 == git* ]]; then
            gpg-connect-agent --quiet --no-autostart updatestartuptty /bye >/dev/null &!
        fi
    }

    autoload -U add-zsh-hook
    add-zsh-hook preexec _preexec_gpg-agent-update-tty
fi

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# Force path arrays to have unique values only
typeset -gU path cdpath fpath manpath
