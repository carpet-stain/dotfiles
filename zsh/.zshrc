# +---------------------+
# | P10K INSTANT PROMPT |
# +---------------------+

# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt
emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh
fi

emulate zsh -c "$(direnv hook zsh)"

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

setopt INC_APPEND_HISTORY_TIME   # history appends to existing file as soon as it's written
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt HIST_REDUCE_BLANKS        # trim multiple insignificant blanks in history
setopt SHARE_HISTORY             # Share history among all sessions

HISTSIZE=1000000
SAVEHIST=$HISTSIZE

# History: Use standard ISO 8601 timestamp.
#   %F is equivalent to %Y-%m-%d
#   %T is equivalent to %H:%M:%S (24-hours format)
HISTTIMEFORMAT='[%F %T]'

unsetopt FLOW_CONTROL            # disable annoying keys 
setopt CLOBBER                   # allow > redirection to truncate existing files
setopt MULTIOS                   # allows multiple input and output redirections 
setopt BRACE_CCL                 # allow brace character class list expansion
unsetopt BEEP                    # do not beep on errors
unsetopt NOMATCH                 # try to avoid the 'zsh: no matches found...'
unsetopt SHORT_LOOPS             # Disable short loop forms
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
setopt NO_SH_WORD_SPLIT          # use zsh style word splitting
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
autoload -Uz select-word-style
select-word-style bash

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

# Ensure add-zsh-hook is loaded
autoload -Uz add-zsh-hook

# Custom personal functions
# Don't use -U as we need aliases here
autoload -z evalcache compdefcache rgf

# +--------------+
# | Key Bindings |
# +--------------+

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Unbind <C-g> so it can be used by fzf-git
bindkey -r "^G"

zmodload zsh/terminfo

typeset -A key
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[Backspace]=${terminfo[kbs]}

# man 5 user_caps
key[CtrlLeft]=${terminfo[kLFT5]}
key[CtrlRight]=${terminfo[kRIT5]}

# Setup keys accordingly
[[ -n ${key[Delete]}    ]] && bindkey ${key[Delete]}    delete-char
[[ -n ${key[Left]}      ]] && bindkey ${key[Left]}      backward-char
[[ -n ${key[Right]}     ]] && bindkey ${key[Right]}     forward-char
[[ -n ${key[Up]}        ]] && bindkey ${key[Up]}        up-line-or-beginning-search
[[ -n ${key[Down]}      ]] && bindkey ${key[Down]}      down-line-or-beginning-search
[[ -n ${key[Backspace]} ]] && bindkey ${key[Backspace]} backward-delete-char
[[ -n ${key[CtrlLeft]}  ]] && bindkey ${key[CtrlLeft]}  backward-word
[[ -n ${key[CtrlRight]} ]] && bindkey ${key[CtrlRight]} forward-word
unset key

# Make dot key autoexpand "..." to "../.." and so on
_zsh-dot () {
    if [[ $LBUFFER = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}

zle -N _zsh-dot
bindkey . _zsh-dot

# +---------------+
# | POWERLEVEL10K |
# +---------------+

source $ZDOTDIR/rc.d/powerlevel10k.zsh

# +---------+
# | ALIASES |
# +---------+

alias ls='eza --long --header --icons --group-directories-first --group --git --all --links'
alias diff=delta

# History suppression
alias clear=' clear'
alias pwd=' pwd'
alias exit=' exit'

# Suppress suggestions and globbing
alias touch='nocorrect touch'
alias mkdir='nocorrect mkdir -pv'
alias cp='nocorrect cp -i --verbose'
alias fd='noglob fd'

alias tmux="tmux -f $DOTFILES/tmux/tmux.conf"

# sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
do_sudo () {
    integer glob=1
    local -a run
    run=(command sudo)
    if [[ $# -gt 1 && $1 = -u ]]; then
        run+=($1 $2)
        shift; shift
    fi
    while (( $# )); do
        case $1 in
            command|exec|-) shift; break ;;
            nocorrect) shift ;;
            noglob) glob=0; shift ;;
            *) break ;;
        esac
    done
    if (( glob )); then
        $run $~==*
    else
        $run $==*
    fi
}

alias sudo='noglob do_sudo '

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

# Completions
source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh

# Key bindings
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh

# Git FZF
source $ZDOTDIR/plugins/fzf-git/fzf-git.sh

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

ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/rc.d/abbreviations-store
[[ -e $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh ]] && 
    source $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh

export MANPATH=$HOMEBREW_PREFIX/opt/zsh-abbr/share/man:$MANPATH

# +--------------------+
# | ZSH-AUTOGUESSTIONS |
# +--------------------+

# Don't rebind widgets by autosuggestion, it's already sourced pretty late
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Enable completion suggestions, if `history` returns nothing
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Ignore suggestions for abbreviations
ZSH_AUTOSUGGEST_HISTORY_IGNORE=${(j:|:)${(Qk)ABBR_REGULAR_USER_ABBREVIATIONS}}
ZSH_AUTOSUGGEST_COMPLETION_IGNORE=$ZSH_AUTOSUGGEST_HISTORY_IGNORE

# Autosuggestion plugin
[[ -e $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Clear suggestions after paste
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# Force path arrays to have unique values only
typeset -U path cdpath fpath manpath
