# Attach to a tmux session, if there's any. Do this only for remote SSH sessions, don't mess local tmux sessions
# Handoff to tmux early, as rest of the rc config isn't needed for this
if (( $+commands[tmux] )) && [[ ! -v TMUX ]] && pgrep -u $EUID tmux &>/dev/null && [[ -v SSH_TTY ]] && [[ ! -v MC_SID ]]; then
    exec tmux attach
fi

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
setopt HIST_IGNORE_SPACE         # don’t store lines starting with space

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
(( $+aliases[run-help] )) && unalias run-help
autoload -Uz run-help
alias help=run-help

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
autoload -z bag evalcache compdefcache man

# +--------------+
# | Key Bindings |
# +--------------+

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

zmodload zsh/terminfo

# Create a zkbd compatible hash
typeset -A key
key[Home]=$terminfo[khome]
key[End]=$terminfo[kend]
key[Insert]=$terminfo[kich1]
key[Delete]=$terminfo[kdch1]
key[Up]=$terminfo[kcuu1]
key[Down]=$terminfo[kcud1]
key[Left]=$terminfo[kcub1]
key[Right]=$terminfo[kcuf1]
key[PageUp]=$terminfo[kpp]
key[PageDown]=$terminfo[knp]
key[Backspace]=$terminfo[kbs]
key[ShiftTab]=$terminfo[kcbt]

# man 5 user_caps
key[CtrlLeft]=$terminfo[kLFT5]
key[CtrlRight]=$terminfo[kRIT5]

# Setup keys accordingly
[[ -n $key[Home]      ]] && bindkey $key[Home]       beginning-of-line
[[ -n $key[End]       ]] && bindkey $key[End]        end-of-line
[[ -n $key[Insert]    ]] && bindkey $key[Insert]     overwrite-mode
[[ -n $key[Delete]    ]] && bindkey $key[Delete]     delete-char
[[ -n $key[Left]      ]] && bindkey $key[Left]       backward-char
[[ -n $key[Right]     ]] && bindkey $key[Right]      forward-char
[[ -n $key[Up]        ]] && bindkey $key[Up]         up-line-or-beginning-search
[[ -n $key[Down]      ]] && bindkey $key[Down]       down-line-or-beginning-search
[[ -n $key[PageUp]    ]] && bindkey $key[PageUp]     beginning-of-buffer-or-history
[[ -n $key[PageDown]  ]] && bindkey $key[PageDown]   end-of-buffer-or-history
[[ -n $key[Backspace] ]] && bindkey $key[Backspace]  backward-delete-char
[[ -n $key[ShiftTab]  ]] && bindkey $key[ShiftTab]   reverse-menu-complete

# MACOS: REMEMBER TO DISABLE MISSION CONTROL KEY BINDINGS IN MACOS SETTINGS FOR THIS TO WORK
# they're not working under tmux256-color
# [[ -n ${key[CtrlLeft]}  ]] && bindkey ${key[CtrlLeft]}   backward-word
# [[ -n ${key[CtrlRight]} ]] && bindkey ${key[CtrlRight]}  forward-word
bindkey "^[[1;5D"   backward-word
bindkey "^[[1;5C"   forward-word

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

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( $+terminfo[smkx] && $+terminfo[rmkx] )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

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
