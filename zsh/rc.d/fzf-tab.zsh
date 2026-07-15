#!/usr/bin/env zsh

source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

# Registers preview zstyles for 200+ commands; not needed until the first Tab
# press, so defer past the first prompt instead of blocking startup. Falls
# back to an eager source when zsh-defer isn't loaded (no controlling
# terminal — .zshrc skips it there, see #96): tab-completion previews are
# meaningless without a real terminal anyway, so loading eagerly in that case
# is harmless.
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

# Simple preview for user-defined expansions
zstyle ':fzf-tab:user-expand:' fzf-preview          'less $word'

zstyle ':fzf-tab:*' fzf-flags ${(Q)${(Z:nC:)FZF_DEFAULT_OPTS}}