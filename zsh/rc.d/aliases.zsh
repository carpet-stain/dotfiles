#!/usr/bin/env zsh

# Parenting changing perms on /
alias chown="chown --preserve-root"

alias df="df -h"
alias dui="dua interactive"
alias du="dua"

alias dig="doggo"
alias diff="delta"
alias tmux="tmux -f $DOTFILES/tmux/tmux.conf"
alias ls="command $EZACMD"

# Git
alias gs="git status"
alias gc="git checkout"
alias gd="git diff"

alias mkdir="mkdir -pv"
alias cp="cp -i --verbose"

# confirmation
alias ln="ln -i"
alias mv="mv -i"

# https://github.com/sindresorhus/guides/blob/main/how-not-to-rm-yourself.md#safeguard-rm
alias rm="rm -I --preserve-root=all"

# Make mount command output pretty and human readable format
alias mount="mount | column -t"

alias rsync="rsync --verbose --archive --human-readable --partial"
alias tree="tree -A -F -C --dirsfirst -a"
alias curl="curlie"
alias find="fd"
alias path='echo -e ${PATH//:/\\n}'
alias fpath='echo -e ${FPATH//:/\\n}'
alias reload="exec ${SHELL} -l"
alias vim="nvim"
alias ip="doggo +short myip.opendns.com @resolver1.opendns.com"


# Colorize help
alias -g -- -h="-h 2>&1 | bat --language=help --style=plain"
alias -g -- --help="--help 2>&1 | bat --language=help --style=plain"
