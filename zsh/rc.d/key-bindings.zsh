#!/usr/bin/env zsh

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Bind some 'CSI u' keys, https://www.leonerd.org.uk/hacks/fixterms/
typeset -A csi

# Create an associative array for CSI key sequences
csi[base]="\e["
csi[suffix]="~"

# Define key sequences for Delete, and Arrow keys
csi[Delete]="3"
csi[Up]="A"
csi[Down]="B"
csi[Right]="C"
csi[Left]="D"

bindkey $csi[base]$csi[Delete]$csi[suffix]  delete-char
bindkey $csi[base]$csi[Left]$csi[suffix]    backward-char
bindkey $csi[base]$csi[Right]$csi[suffix]   forward-char
bindkey $csi[base]$csi[Up]$csi[suffix]      up-line-or-beginning-search
bindkey $csi[base]$csi[Down]$csi[suffix]    down-line-or-beginning-search
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

# Expand aliases
expand-alias () {
    zle _expand_alias
    # Remove the leading backslash if present
    [[ $LBUFFER == "\\"* ]] && LBUFFER=${LBUFFER:1}
    zle self-insert
}

zle  -N expand-alias
bindkey -M main ' ' expand-alias