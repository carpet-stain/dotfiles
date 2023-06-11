# +---------+
# | FZF-TAB |
# +---------+

zstyle :fzf-tab:* prefix ''

print "sourcing fzf-tab"

# complete
zstyle :fzf-tab:complete:* fzf-preview 'less ${realpath#-*=}'

# User expand
zstyle ':fzf-tab:user-expand:' fzf-preview 'less $word'

# Command
 zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
  ¦ '(out=$(tldr --color always "$word") 2>/dev/null && echo $out) || (out=$(MANWIDTH=$FZF_PREVIEW_COLUMNS man "$word") 2>/dev/null && echo $out) || (out=$(which "$word") && echo $out) || echo "${(P)word}"'

# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath' # remember to use single quote here!!!

# Environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

# bat
zstyle ':fzf-tab:complete:(\\|*/|)bat:*-argument-rest' fzf-preview \
'case "$group" in
subcommand)
  bat cache --help | bat --color=always -plhelp
  ;;
*)
  [[ -f ${realpath#--*=} ]] && bat ${realpath#--*=} || less ${realpath#--*=}
  ;;
esac'

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
zstyle ':fzf-tab:complete:(\\|*/|)df:argument-rest' fzf-preview '[[ $group != 'device label' ]] && grc --colour=on df -Th $word'

# Go
zstyle ':fzf-tab:complete:(\\|*/|)go:argument-1' fzf-preview 'go help $word | bat --color=always -plhelp'

# jq
zstyle ':fzf-tab:complete:(\\|*/|)jq:*-argument-rest' fzf-preview \
'[[ -f $realpath ]] && jq -Cr . $realpath 2>/dev/null || less $realpath'

# Make
zstyle ':fzf-tab:complete:(\\|*/|)(g|b|d|p|freebsd-|)make:' fzf-preview \
"case $group in
'make target')
  make -n $word | bat --color=always -plsh
  ;;
'make variable')
  make -pq | rg -Ns "^$word = " | bat --color=always -plsh
  ;;
file)
  less ${realpath#--*=}
  ;;
esac"

# Man
zstyle ':fzf-tab:complete:(\\|*/|)man:' fzf-preview 'man $word | bat --color=always -plman'

# nmap
zstyle ':fzf-tab:complete:(\\|*/|)nmap:argument-rest' fzf-preview 'nmap $word'

# ps
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,command -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps -p $word -o command -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# pipx
zstyle ':fzf-tab:complete:(\\|*/|)pipx:' fzf-preview 'pipx $word --help | bat --color=always -plhelp'

# pyenv
zstyle ':fzf-tab:complete:(\\|*/|)pyenv:' fzf-preview 'pyenv help $word | bat --color=always -plhelp'

# python
zstyle ':fzf-tab:complete:(\\|*/|)python:option-m-1' fzf-preview 'pydoc3 $word | bat --color=always -plman'

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
zstyle ':fzf-tab:complete:(\\|*/|)tar:' fzf-preview 'tar tvaf $word'

# tldr
zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview 'tldr --color always $word'

# tmux
zstyle ':fzf-tab:complete:tmux:argument-rest' fzf-preview \
"case $word in
(show|set)(env|-environment))
  tmux ${word/set/show} -g | bat --color=always -plsh
  ;;
(show|set)(-hook?|(-window)-option?|w|))
  tmux ${word/set/show} -g | bat --color=always -pltsv
  ;;
(show|set)(msgs|-message?))
  tmux ${word/set/show} | bat --color=always -pllog
  ;;
(show|set)(b|-buffer))
  tmux ${word/set/show}
  ;;
(ls|list-)*)
  tmux $word
  ;;
esac"

# switch group using `,` and `.`
zstyle :fzf-tab:* switch-group ',' '.'