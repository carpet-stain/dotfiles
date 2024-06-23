# +---------+
# | FZF-TAB |
# +---------+

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
  run-help $word | bat --color=always -plman
  ;;
parameter)
  echo ${(P)word}
  ;;
esac'

# Parameter
zstyle ':fzf-tab:complete:((-parameter-|unset):|(export):argument-rest)' fzf-preview \
'echo ${(P)word}'

# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --long --header --icons --group-directories-first --group --git --all --links --color=always $realpath' # remember to use single quote here!!

# Man
zstyle ':fzf-tab:complete:(\\|*/|)man:' fzf-preview 'man $word | bat -plman'

# scp
zstyle ':fzf-tab:complete:(\\|*/|)(scp|rsync):argument-rest' fzf-preview \
"case $group in
file)
  less ${realpath#--*=}
  ;;
user)
  finger $word
  ;;
*host*)
  grc --colour=on ping -c1 $word
  ;;
esac"

# switch group using `<` and `>`
zstyle :fzf-tab:* switch-group '<' '>'
