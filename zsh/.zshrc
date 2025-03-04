# +------+
# | TMUX |
# +------+

# Start tmux, if it's first terminal tab, skip this on remote sessions and root/sudo
# Handoff to tmux early, as rest of the rc config isn't needed for this
if [[ ! -v TMUX && ! -v SSH_TTY && ${EUID} != 0 ]] && ! tmux list-sessions &>/dev/null; then
    exec tmux -f $DOTFILES/tmux/tmux.conf new-session -s personal
fi

# +---------------------+
# | P10K INSTANT PROMPT |
# +---------------------+

# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt
emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r $XDG_CACHE_HOME:-$HOME/.cache/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source $XDG_CACHE_HOME:-$HOME/.cache/p10k-instant-prompt-${(%):-%n}.zsh
fi

emulate zsh -c "$(direnv hook zsh)"

# +--------+
# | SETOPT |
# +--------+

source $ZDOTDIR/rc.d/setopt.zsh

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

source $ZDOTDIR/rc.d/key-bindings.zsh

# +---------------+
# | POWERLEVEL10K |
# +---------------+

source $ZDOTDIR/rc.d/powerlevel10k.zsh

# +---------+
# | ALIASES |
# +---------+

# Prefer abbreviations over alias
alias ls='eza --icons --group-directories-first --all'

# +-------------+
# | COMPLETIONS |
# +-------------+

# Compinit is called here
source $ZDOTDIR/rc.d/completions.zsh

# +--------+
# | ZOXIDE |
# +--------+

# zoxide needs to be called after compinit
eval "$(zoxide init zsh)"

# +-----+
# | FZF |
# +-----+

source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh

# +---------+
# | FZF-TAB |
# +---------+

source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh

# +------------------------------+
# | ZSH-FAST-SYNTAX-HIGHLIGHTING |
# +------------------------------+

# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis $@; fi; }

source $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fast-theme XDG:catppuccin-mocha &>/dev/null

# +----------+
# | ZSH-ABBR |
# +----------+

ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/rc.d/abbreviations-store

# When an abbreviation expands, also push the expanded text to history.
ABBR_EXPAND_PUSH_ABBREVIATION_TO_HISTORY=1

# Enable a command to retrieve available abbreviations.
ABBR_GET_AVAILABLE_ABBREVIATION=1

# Log available abbreviations after execution.
ABBR_LOG_AVAILABLE_ABBREVIATION_AFTER=1

ZSH_ABBR_CACHE_DIR=$XDG_CACHE_HOME/zsh-abbr
source $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh

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

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Clear suggestions after paste
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# Force path arrays to have unique values only
typeset -U path cdpath fpath manpath
