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

HISTFILE="$XDG_STATE_HOME"/zsh/history
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
autoload -z bag evalcache compdefcache

# +--------------+
# | Key Bindings |
# +--------------+

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

zmodload zsh/terminfo

# Create a zkbd compatible hash
typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Backspace]=${terminfo[kbs]}
key[ShiftTab]=${terminfo[kcbt]}

# man 5 user_caps
key[CtrlLeft]=${terminfo[kLFT5]}
key[CtrlRight]=${terminfo[kRIT5]}

# Setup keys accordingly
[[ -n ${key[Home]}      ]] && bindkey ${key[Home]}       beginning-of-line
[[ -n ${key[End]}       ]] && bindkey ${key[End]}        end-of-line
[[ -n ${key[Insert]}    ]] && bindkey ${key[Insert]}     overwrite-mode
[[ -n ${key[Delete]}    ]] && bindkey ${key[Delete]}     delete-char
[[ -n ${key[Left]}      ]] && bindkey ${key[Left]}       backward-char
[[ -n ${key[Right]}     ]] && bindkey ${key[Right]}      forward-char
[[ -n ${key[Up]}        ]] && bindkey ${key[Up]}         up-line-or-beginning-search
[[ -n ${key[Down]}      ]] && bindkey ${key[Down]}       down-line-or-beginning-search
[[ -n ${key[PageUp]}    ]] && bindkey ${key[PageUp]}     beginning-of-buffer-or-history
[[ -n ${key[PageDown]}  ]] && bindkey ${key[PageDown]}   end-of-buffer-or-history
[[ -n ${key[Backspace]} ]] && bindkey ${key[Backspace]}  backward-delete-char
[[ -n ${key[ShiftTab]}  ]] && bindkey ${key[ShiftTab]}   reverse-menu-complete

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
if (( ${+terminfo[smkx]} && $+terminfo[rmkx] )); then
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

command -v curlie &> /dev/null && alias curl=curlie
command -v fd     &> /dev/null && alias fd='fd --hidden --follow'                            || alias fd='find . -name'
command -v rg     &> /dev/null && alias rg='rg --hidden --follow --smart-case 2>/dev/null'   || alias rg='grep --color=auto --exclude-dir=.git -R --binary-files=without-match --devices=skip'
command -v exa    &> /dev/null && alias ls='exa --long --header --icons --group-directories-first --group --git --all --links' || alias ls='ls --color=auto --group-directories-first -h'
command -v dog    &> /dev/null && alias d=dog                                                || alias d='dig +nocmd +multiline +noall +answer'

# Some handy suffix aliases
alias -s log=less

# Enable delta
alias diff=delta

# Make mount command output pretty and human readable format
alias mount='mount |column -t'

# Human file sizes
alias df='df -Th'
alias du=dua
alias dui='dua interactive'

# Handy stuff and a bit of XDG compliance
alias tmux='tmux -f $DOTFILES/tmux/tmux.conf'
command -v wget &> /dev/null && alias wget='wget --continue --hsts-file=$XDG_CACHE_HOME/wget-hsts'

# History suppression
alias clear=' clear'
alias pwd=' pwd'
alias exit=' exit'

# Do not delete / or prompt if deleting more than 3 files at a time #
alias rm='rm -I --preserve-root'

# confirmation
alias mv='mv -i'
alias ln='ln -i'

# Suppress suggestions and globbing
alias find='noglob find'
alias touch='nocorrect touch'
alias mkdir='nocorrect mkdir -pv'
alias cp='nocorrect cp -i'
alias ag='noglob ag'
alias fd='noglob fd'

# Parenting changing perms on /
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

alias rsync='rsync --verbose --archive --info=progress2 --human-readable --partial'
alias tree='tree -a -I .git --dirsfirst'

# sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
do_sudo () {
    integer glob=1
    local -a run
    run=(command sudo)
    if [[ ${#} -gt 1 && $1 = -u ]]; then
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

# +--------+
# | COLORS |
# +--------+

# Color man
# Set originally "bold" as "bold and red"
# Set originally "underline" as "underline and green"
man () {
    # termcap codes
    # md    start bold
    # mb    start blink
    # me    turn off bold, blink and underline
    # so    start standout (reverse video)
    # se    stop standout
    # us    start underline
    # ue    stop underline
    LESS_TERMCAP_md=$(echoti bold; echoti setaf 1) \
    LESS_TERMCAP_mb=$(echoti blink) \
    LESS_TERMCAP_me=$(echoti sgr0) \
    LESS_TERMCAP_so=$(echoti smso) \
    LESS_TERMCAP_se=$(echoti rmso) \
    LESS_TERMCAP_us=$(echoti smul; echoti setaf 2) \
    LESS_TERMCAP_ue=$(echoti sgr0) \
    nocorrect noglob command man $@
}

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
source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh(N)

# Key bindings
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh(N)

# +---------+
# | FZF-TAB |
# +---------+

# Use fzf for tab completions
source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh
source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh(N)

# +------------------------------+
# | ZSH-FAST-SYNTAX-HIGHLIGHTING |
# +------------------------------+

# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis $@; fi; }

# syntax-highlighting plugin
source $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh(N)

# +----------+
# | ZSH-ABBR |
# +----------+

ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/plugins/abbreviations-store
source $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh(N)
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
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh(N)

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
