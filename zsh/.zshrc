# +------+
# | TMUX |
# +------+

# # Start tmux if it's the first terminal tab, skipping on remote sessions and root/sudo
# # If tmux is running, invoke _sesh-sessions instead to select an available session
if [[ ! -v SSH_TTY && $EUID != 0 ]]; then
  # If tmux is not running on the system
  if ! pgrep -x tmux &> /dev/null; then
    echo 'Tmux is not running, starting a new session...'
    exec tmux -f "$DOTFILES/tmux/tmux.conf" new-session -s personal

  # If tmux is running, but we're not inside a tmux session
  elif [[ -z $TMUX ]]; then
    autoload -Uz _sesh-sessions
    _sesh-sessions
  fi
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

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Bind some 'CSI u' keys, https://www.leonerd.org.uk/hacks/fixterms/
typeset -A csi

# Create an associative array for CSI key sequences
csi[base]="\e["
csi[suffix]="~"
csi[alt-S]="\es"

# Define key sequences for Delete, and Arrow keys
csi[Delete]="3"
csi[Up]="A"
csi[Down]="B"
csi[Right]="C"
csi[Left]="D"

bindkey $csi[base]$csi[Delete]$csi[suffix]  delete-char
bindkey $csi[base]$csi[Left]$csi[suffix]    backward-char
bindkey $csi[base]$csi[Right]$csi[suffix]   forward-char
bindkey $csi[base]$csi[Up]$csi[suffix]      up-line-or-beginning-search
bindkey $csi[base]$csi[Down]$csi[suffix]    down-line-or-beginning-search
bindkey $csi[alt-S]                         _sesh-sessions
unset csi

bindkey . _zsh-dot

bindkey ' ' _expand-alias

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

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste new-command _zsh-dot)

# +--------+
# | FORGIT |
# +--------+

source $HOMEBREW_PREFIX/opt/forgit/share/forgit/forgit.plugin.zsh

# +----------------+
# | SANITIZE PATHS |
# +----------------+

# Force path arrays to have unique values only
typeset -U path fpath manpath
