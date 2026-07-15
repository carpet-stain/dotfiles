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

# .zshenv already ran direnv export before this file was sourced — satisfies
# p10k's own requirement that it run above the instant prompt block:
# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt

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

# Lets non-critical plugins load after the first prompt instead of blocking
# startup. zsh-defer's whole job is deferring work until zle goes idle, so it
# needs a real controlling terminal — without one (e.g. `zsh -is` in
# linux/deploy.sh, or an SSH session without -tt) its `zle -N`/`zle -F` calls
# print "can't change option: zle" to stderr (see #96). Load it only when
# stdout is a tty; rc.d/fzf-tab.zsh falls back to an eager `source` when the
# `zsh-defer` function isn't defined.
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

# Syntax highlighting; replaced fast-syntax-highlighting — swap rationale
# and fsh's retired fsh#27 `whatis` workaround: see #92. Theme comes from
# zsh-patinaconfig.toml (built-in catppuccin-mocha, no compile step).
#
# Must come after compinit/bindkey (completions.zsh runs compinit above) or
# the highlighter has no effect until a manual `source` — see zsh-patina's
# own troubleshooting docs.
eval "$(zsh-patina activate)"

# +------+
# | DEJA |
# +------+

# Ghost-text suggestions (fuzzy/directory/sequence-aware); replaced
# zsh-autosuggestions — swap rationale: see #92. Stands down on its own if
# zsh-autosuggestions is also loaded, so both can coexist safely.
eval "$(deja init zsh)"

# +-----------------+
# | YOU-SHOULD-USE  |
# +-----------------+

# Reminds you when a command you just typed has a shorter alias (see #90).
# The regular command-replacement aliases (cat→bat, ls→eza, …) and git
# aliases are where the nudge helps; the global shorthands in aliases.zsh
# (NUL, F, C, J, --help) are deliberate keystroke-savers whose *values*
# (`>/dev/null 2>&1`, `| fzf`, …) are common substrings that would fire on
# nearly every line, so they're silenced. YSU_MODE defaults to BESTMATCH
# (one hint, not every match); "after" prints the hint below the command
# output instead of before it.
export YSU_MESSAGE_POSITION="after"
export YSU_IGNORED_GLOBAL_ALIASES=('--help' J C F NUL)
source $XDG_DATA_HOME/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh
