# +---------+
# | ALIASES |
# +---------+

alias fd='fd --hidden --follow'
alias rg='rg --hidden --follow --smart-case 2>/dev/null'
alias ls='exa --long --header --icons --group-directories-first --group --git --all --links'

# Some handy suffix aliases
alias -s log=less

# Enable delta
alias diff=delta

# Make mount command output pretty and human readable format
alias mount='mount | column -t'

# Human file sizes
alias df='df -Th'
alias du=dua
alias dui='dua interactive'

# Handy stuff and a bit of XDG compliance
alias tmux='tmux -f $DOTFILES/tmux/tmux.conf'
alias wget='wget --continue --hsts-file=$XDG_CACHE_HOME/wget-hsts'
alias ssh='ssh -F $XDG_CONFIG_HOME/ssh/config'

# History suppression
alias clear=' clear'
alias pwd=' pwd'
alias exit=' exit'

# Prompt if deleting more than 3 files at a time #
alias rm='rm -I'

# confirmation
alias mv='mv -i'
alias ln='ln -i'

# Suppress suggestions and globbing
alias find='noglob find'
alias touch='nocorrect touch'
alias mkdir='nocorrect mkdir -pv'
alias cp='nocorrect cp -i'
alias fd='noglob fd'

# Parenting changing perms on /
alias chown='chown --preserve-root'

alias rsync='rsync --verbose --archive --info=progress2 --human-readable --partial'
alias tree='tree -a -I .git --dirsfirst'

# sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
do_sudo () {
    integer glob=1
    local -a run
    run=(command sudo)
    if [[ $# -gt 1 && $1 = -u ]]; then
        run+=($1 $2)
        shift; shift
    fi
    while (( $# )); do
        case $1 in
            command|exec|-) shift; break ;;
            nocorrect) shift ;;
            noglob) glob=0; shift ;;
            *) break ;;
        esac
    done
    if (( glob )); then
        $run $~==*
    else
        $run $==*
    fi
}
alias sudo='noglob do_sudo '