# .zshrc is sourced only for interactive shells.
# Plugin loading, key bindings, completions, and prompt configuration live here.

# +--------+
# | ZELLIJ |
# +--------+

# grep -v EXITED is load-bearing: list-sessions exits 0 for resurrectable dead
# sessions too, and only a running one should skip straight to attaching.
if [[ -z $CI && -z $SSH_TTY && $EUID != 0 ]]; then
  local _zellij_active=$(zellij list-sessions --no-formatting 2>/dev/null | grep -v 'EXITED')
  if [[ -z $_zellij_active ]]; then
    print "Zellij is not running, starting a new session..."
    # attach --create resurrects a dead "default" session; plain --session
    # errors instead when one is already on record.
    exec zellij attach --create default
  elif [[ -z $ZELLIJ ]]; then
    autoload -Uz _zellij-sessions
    _zellij-sessions
  fi
  unset _zellij_active
fi

# +---------------------+
# | P10K INSTANT PROMPT |
# +---------------------+

# Ordering requirement: .zshenv already ran direnv export, which p10k requires
# above the instant prompt block (its README, "how do I initialize direnv").

# Anything that may need console input (password prompts, [y/n] confirmations)
# must go above this block.
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

# +-----------+
# | ZSH-DEFER |
# +-----------+

# Needs a controlling terminal — without one its zle calls spam stderr (#96).
# rc.d/fzf-tab.zsh falls back to an eager source when zsh-defer is undefined.
[[ -t 1 ]] && source $ZDOTDIR/plugins/zsh-defer/zsh-defer.plugin.zsh

# +---------+
# | FZF-TAB |
# +---------+

# Must come after fzf — overrides fzf's own tab completion handler
source $ZDOTDIR/rc.d/fzf-tab.zsh

# +--------------+
# | ZSH-AUTOPAIR |
# +--------------+

# Auto-closes/deletes matching brackets and quotes
source $XDG_DATA_HOME/zsh/plugins/zsh-autopair/autopair.zsh

# +-------------+
# | ZSH-PATINA  |
# +-------------+

# Must come after compinit/bindkey or the highlighter is inert (#92). Set here,
# not .zshenv: the daemon reads it at `activate` below, its only consumer.
if [[ $THEME_MODE == light ]]; then
  export ZSH_PATINA_CONFIG_PATH=$XDG_CONFIG_HOME/zsh-patina/config-latte.toml
else
  export ZSH_PATINA_CONFIG_PATH=$XDG_CONFIG_HOME/zsh-patina/config-mocha.toml
fi
eval "$(zsh-patina activate)"

# +------+
# | DEJA |
# +------+

# Ghost-text suggestions, replaced zsh-autosuggestions (#92). Must be set
# before the eval: deja's default Tab cycle shadows fzf-tab's picker (#428).
export DEJA_CYCLE_KEY='^[[Z'
eval "$(deja init zsh)"
