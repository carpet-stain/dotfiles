#!/usr/bin/env zsh

# Use emacs keybindings even if $EDITOR is set to vi
bindkey -e

# +-----------+
# | TERMINAL  |
# +-----------+

# Bind keys via terminfo so sequences match whatever $TERM reports.
# Guards prevent errors if a capability is absent (e.g., a minimal TERM value).
typeset -A key
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}

[[ -n ${key[Delete]} ]] && bindkey ${key[Delete]} delete-char
[[ -n ${key[Left]}   ]] && bindkey ${key[Left]}   backward-char
[[ -n ${key[Right]}  ]] && bindkey ${key[Right]}  forward-char
[[ -n ${key[Up]}     ]] && bindkey ${key[Up]}     up-line-or-beginning-search
[[ -n ${key[Down]}   ]] && bindkey ${key[Down]}   down-line-or-beginning-search

# +---------+
# | WIDGETS |
# +---------+

# '.' smart expansion: single dot → cd ./, double dot → cd ../, more dots → append /..
bindkey '.' _zsh-dot

# Space expands aliases inline; prefix with backslash to suppress
bindkey ' ' _expand-alias
