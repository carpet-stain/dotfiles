# +---------+
# | FZF-TAB |
# +---------+

source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

zstyle :fzf-tab:* prefix ''
zstyle :fzf-tab:* continuous-trigger space
zstyle :fzf-tab:* fzf-bindings tab:accept
zstyle :fzf-tab:* accept-line enter

# User expand
zstyle ':fzf-tab:user-expand:' fzf-preview 'less $word'

# Command
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

# Parameter
zstyle ':fzf-tab:complete:((-parameter-|unset):|(export):argument-rest)' fzf-preview \
'echo ${(P)word}'

# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --long --header --icons --group-directories-first --group --git --all --links --color=always $realpath' # remember to use single quote here!!

# switch group using `<` and `>`
zstyle :fzf-tab:* switch-group '<' '>'
