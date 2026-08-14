#!/usr/bin/env zsh

source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

# Deferred past the first prompt: its 200+ preview zstyles aren't needed until the
# first Tab. Eager fallback when zsh-defer is absent (no tty — see #96).
if (( $+functions[zsh-defer] )); then
  zsh-defer source $ZDOTDIR/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh
else
  source $ZDOTDIR/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh
fi

# +------------------------+
# |  GENERAL FZF-TAB SETTINGS  |
# +------------------------+

# Re-trigger completion on <space> (e.g. 'git che<space>' -> 'git checkout ')
zstyle ':fzf-tab:*'            continuous-trigger   space

# Remap keys inside the fzf menu
zstyle ':fzf-tab:*'            fzf-bindings         'tab:down' 'shift-tab:up' 'enter:accept'

# Accept the selection immediately on Enter
zstyle ':fzf-tab:*'            accept-line          enter

# Keys to switch between groups (e.g., "processes" vs "files")
zstyle ':fzf-tab:*'            switch-group         '<' '>'

# Style of the active group's header when switching groups
zstyle ':fzf-tab:*'            active-group-style   bold

# Simple preview for user-defined expansions
zstyle ':fzf-tab:user-expand:' fzf-preview          'less $word'

zstyle ':fzf-tab:*' fzf-flags ${(Q)${(Z:nC:)FZF_DEFAULT_OPTS}}
