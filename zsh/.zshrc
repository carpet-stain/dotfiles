# +------+
# | TMUX |
# +------+

# Start tmux, if it's first terminal tab, skip this on remote sessions and root/sudo
# Handoff to tmux early, as rest of the rc config isn't needed for this
if [[ ! -v TMUX && ! -v SSH_TTY && $EUID != 0 ]] && ! tmux list-sessions &> /dev/null; then
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
if [[ -r $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh
fi

emulate zsh -c "$(direnv hook zsh)"

# +--------+
# | SETOPT |
# +--------+

source $ZDOTDIR/rc.d/setopt.zsh

# +----------+
# | AUTOLOAD |
# +----------+

source $ZDOTDIR/rc.d/autoload.zsh

# +--------------+
# | Key Bindings |
# +--------------+

source $ZDOTDIR/rc.d/key-bindings.zsh

# +---------+
# | ALIASES |
# +---------+

source $ZDOTDIR/rc.d/aliases.zsh

# +---------------+
# | POWERLEVEL10K |
# +---------------+

source $ZDOTDIR/rc.d/powerlevel10k.zsh

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

# +--------------------+
# | ZSH-AUTOGUESSTIONS |
# +--------------------+

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Enable completion suggestions, if `history` returns nothing
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Clear suggestions after paste
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste new-command)

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# Force path arrays to have unique values only
typeset -U path fpath manpath
