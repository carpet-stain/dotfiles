#!/usr/bin/env zsh

source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

# General fzf-tab Settings
zstyle :fzf-tab:*            prefix             ''
zstyle :fzf-tab:*            continuous-trigger space
zstyle :fzf-tab:*            fzf-bindings       tab:accept
zstyle :fzf-tab:*            accept-line        enter
zstyle :fzf-tab:*            switch-group       '<' '>'

# User expand
zstyle :fzf-tab:user-expand: fzf-preview        'less $word'

# Command completion preview
zstyle ':fzf-tab:complete:(-command-:|command:option-(v|V)-rest)' fzf-preview \
'case $group in
"external command")
  less =$word
  ;;
"executable file")
  less ${realpath#--*=}
  ;;
"builtin command")
  run-help $word | bat -plman
  ;;
parameter)
  echo ${(P)word}
  ;;
esac'

# Parameter completion preview
zstyle ':fzf-tab:complete:((-parameter-|unset):|(export):argument-rest)' fzf-preview \
'echo ${(P)word}'

# Directory content preview with eza for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --group-directories-first --all --color=always $realpath' # remember to use single quote here!!
