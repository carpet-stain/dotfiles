# .zshrc is sourced only for interactive shells.
# Plugin loading, key bindings, completions, and prompt configuration live here.

# +--------+
# | ZELLIJ |
# +--------+

# Skip on remote sessions and root — those should not auto-attach.
# Three states: no active session → start one; a session exists but we're not
# attached → pick one; already inside zellij → do nothing.
# "Active" excludes exited-but-resurrectable sessions (list-sessions marks
# those "EXITED" and still exits 0 for them; only a genuinely running session
# should skip straight to attaching).
if [[ -z $CI && -z $SSH_TTY && $EUID != 0 ]]; then
  local _zellij_active=$(zellij list-sessions --no-formatting 2>/dev/null | grep -v 'EXITED')
  if [[ -z $_zellij_active ]]; then
    print "Zellij is not running, starting a new session..."
    # attach --create both resurrects a dead "default" session and creates a
    # fresh one if none exists yet — plain --session errors instead of
    # resurrecting when a dead session of that name is already on record.
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

# +-----------+
# | ZSH-DEFER |
# +-----------+

# Lets non-critical plugins load after the first prompt instead of blocking startup
source $ZDOTDIR/plugins/zsh-defer/zsh-defer.plugin.zsh

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

source $XDG_DATA_HOME/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
