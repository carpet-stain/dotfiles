#!/usr/bin/env zsh

# Source the fzf-tab plugin from its submodule location
source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh
source $ZDOTDIR/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh

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

# Simple preview for user-defined expansions
zstyle ':fzf-tab:user-expand:' fzf-preview          'less $word'

zstyle ':fzf-tab:*' fzf-flags ${(Q)${(Z:nC:)FZF_DEFAULT_OPTS}}