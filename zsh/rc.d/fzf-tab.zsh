# +---------+
# | FZF-TAB |
# +---------+

zstyle :fzf-tab:* prefix ''

# Uses tmux popup
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# zstyle ':fzf-tab:*' popup-min-size 100 100
zstyle ':fzf-tab:complete:*' popup-pad 200 50

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
zstyle ':fzf-tab:complete:((-parameter-|unset):|(export|typeset|declare|local):argument-rest)' fzf-preview \
'echo ${(P)word}'

# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa --long --header --icons --group-directories-first --group --git --all --links --color=always $realpath' # remember to use single quote here!!

# Docker
zstyle ':fzf-tab:complete:docker-container:argument-1' fzf-preview 'docker container $word --help | bat --color=always -plhelp'
zstyle ':fzf-tab:complete:docker-image:argument-1' fzf-preview 'docker image $word --help | bat --color=always -plhelp'
zstyle ':fzf-tab:complete:docker-inspect:' fzf-preview 'docker inspect $word | bat --color=always -pljson'
zstyle ':fzf-tab:complete:docker-(run|images):argument-1' fzf-preview 'docker images $word'
zstyle ':fzf-tab:complete:((\\|*/|)docker|docker-help):argument-1' fzf-preview 'docker help $word | bat --color=always -plhelp'

# Homebrew
zstyle ':fzf-tab:complete:brew-((|un)install|info|cleanup):*-argument-rest' fzf-preview 'brew info $word | bat --color=always -plyaml'
zstyle ':fzf-tab:complete:brew-(list|ls):*-argument-rest' fzf-preview 'brew list $word'

# df
zstyle ':fzf-tab:complete:(\\|*/|)df:argument-rest' fzf-preview '[[ $group != "device label" ]] && grc --colour=on df -Th $word'

# Go
zstyle ':fzf-tab:complete:(\\|*/|)go:argument-1' fzf-preview 'go help $word | bat --color=always -plhelp'

# Man
zstyle ':fzf-tab:complete:(\\|*/|)man:' fzf-preview 'man $word | bat --color=always -plman'

# nmap
zstyle ':fzf-tab:complete:(\\|*/|)nmap:argument-rest' fzf-preview 'nmap -Pn $word'

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

# tar
zstyle ':fzf-tab:complete:(\\|*/|)tar:' fzf-preview 'tar tvf $word'

# switch group using `,` and `.`
zstyle :fzf-tab:* switch-group ',' '.'