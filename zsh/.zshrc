# .zshrc is sourced only for interactive shells.
# Plugin loading, key bindings, completions, and prompt configuration live here.

# +------+
# | TMUX |
# +------+

# Skip on remote sessions and root — those should not auto-attach.
# Three states: tmux absent → start session; tmux present but unattached → pick session; inside tmux → do nothing.
if [[ -z $SSH_TTY && $EUID != 0 ]]; then
  if ! pgrep -x tmux &> /dev/null; then
    print "Tmux is not running, starting a new session..."
    exec tmux -f $DOTFILES/tmux/tmux.conf new-session -s personal
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
[[ -r $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh ]] && \
  source $XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh

emulate zsh -c "$(direnv hook zsh)"

# +---------+
# | OPTIONS |
# +---------+

source $ZDOTDIR/rc.d/options.zsh

# +---------+
# | WIDGETS |
# +---------+

source $ZDOTDIR/rc.d/widgets.zsh

# +--------------+
# | KEY BINDINGS |
# +--------------+

source $ZDOTDIR/rc.d/keybindings.zsh

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

source $ZDOTDIR/rc.d/completions.zsh

# +--------+
# | ZOXIDE |
# +--------+

# Must come after compinit
eval "$(zoxide init zsh)"

# +-----+
# | FZF |
# +-----+

# Must come after compinit; sets up Ctrl+T, Ctrl+R, Alt+C bindings and tab completion
eval "$(fzf --zsh)"

# +---------+
# | FZF-TAB |
# +---------+

# Must come after fzf — overrides fzf's own tab completion handler
source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh

# +------------------------------+
# | ZSH-FAST-SYNTAX-HIGHLIGHTING |
# +------------------------------+

# FSH clobbers the whatis builtin; skip it when fzf-tab's THEFD file descriptor is active
# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis "$@"; fi; }

source $ZDOTDIR/plugins/fsh/fast-syntax-highlighting.plugin.zsh

# `fast-theme` writes a compiled theme cache; deploy.zsh runs it once, so just
# source the cache here instead of re-running the (much heavier) command on
# every shell startup. Self-heals if the cache is missing (e.g. before deploy).
FAST_THEME_CACHE=$XDG_CACHE_HOME/fast-syntax-highlighting/current_theme.zsh
if [[ -r $FAST_THEME_CACHE ]]; then
  source $FAST_THEME_CACHE
else
  fast-theme -q XDG:catppuccin-mocha
fi
unset FAST_THEME_CACHE

# +---------------------+
# | ZSH-AUTOSUGGESTIONS |
# +---------------------+

# Config must be set before sourcing the plugin
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste new-command _zsh-dot)

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# +--------+
# | FORGIT |
# +--------+

# Interactive git commands via fzf (ga, glo, gi, …); needs fzf loaded above
source $HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh
