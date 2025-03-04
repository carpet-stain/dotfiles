#!/usr/bin/env zsh

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

zmodload zsh/terminfo

typeset -A key
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[Backspace]=${terminfo[kbs]}
key[Enter]=${terminfo[cr]}

# Setup keys accordingly
[[ -n ${key[Delete]}    ]] && bindkey ${key[Delete]}    delete-char
[[ -n ${key[Left]}      ]] && bindkey ${key[Left]}      backward-char
[[ -n ${key[Right]}     ]] && bindkey ${key[Right]}     forward-char
[[ -n ${key[Up]}        ]] && bindkey ${key[Up]}        up-line-or-beginning-search
[[ -n ${key[Down]}      ]] && bindkey ${key[Down]}      down-line-or-beginning-search
[[ -n ${key[Backspace]} ]] && bindkey ${key[Backspace]} backward-delete-char
[[ -n ${key[Enter]}     ]] && bindkey ${key[Enter]}     accept-line
unset key

# Also bind some 'CSI u' keys, https://www.leonerd.org.uk/hacks/fixterms/
typeset -A csi

# Create an associative array for CSI key sequences
csi[base]="\e["
csi[special-suffix]="~"

# Define key sequences for Home, End, Insert, Delete, and Arrow keys
csi[special-Delete]="3"
csi[really-special-Up]="A"
csi[really-special-Down]="B"
csi[really-special-Right]="C"
csi[really-special-Left]="D"

bindkey ${csi[base]}${csi[special-Delete]}${csi[special-suffix]}                        delete-char
bindkey ${csi[base]}${csi[special-Left]}${csi[special-suffix]}                          backward-char
bindkey ${csi[base]}${csi[special-Right]}${csi[special-suffix]}                         forward-char
bindkey ${csi[base]}${csi[special-Up]}${csi[special-suffix]}                            up-line-or-beginning-search
bindkey ${csi[base]}${csi[special-Down]}${csi[special-suffix]}                          down-line-or-beginning-search
unset csi

# Make dot key autoexpand "..." to "../.." and so on
_zsh-dot () {
    if [[ -z $LBUFFER ]]; then
        LBUFFER=.
    elif [[ $LBUFFER = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}

zle -N _zsh-dot
bindkey . _zsh-dot