#!/usr/bin/env zsh

# Use emacs keybindings (like Ctrl-A, Ctrl-E) even if $EDITOR is set to vi.
# This is the Zsh default, but we set it explicitly for consistency.
bindkey -e

# +-------------------------------+
# |  MODERN TERMINAL KEY FIXES    |
# +-------------------------------+

# Bind modern terminal escape sequences (CSI u / "fixterms").
# This is a compatibility fix for modern terminals (like Alacritty, iTerm2, etc.)
# It ensures keys like Delete and the Arrow keys work correctly,
# as they may send different escape codes than legacy terminals.
# See: https://www.leonerd.org.uk/hacks/fixterms/

# Use an associative array (hash map) to build the key sequences cleanly.
typeset -A csi

# Define key sequence parts
csi[base]="\e[" # All sequences start with Escape-[
csi[suffix]="~"  # Suffix for keys like Delete, Home, End

# Key-specific codes
csi[Delete]="3"
csi[Up]="A"
csi[Down]="B"
csi[Right]="C"
csi[Left]="D"

# Modifier Keys (Ctrl/Alt + Arrow)
# 1;3 = Alt modifier in xterm/tmux
csi[AltRight]="1;3C"
csi[AltLeft]="1;3D"

# Bind the assembled sequences.
# Bind Delete (e.g., "\e[3~") to 'delete-char'
bindkey $csi[base]$csi[Delete]$csi[suffix]  delete-char
# Bind tilde-suffixed arrow keys (e.g., "\e[D~", "\e[A~")
bindkey $csi[base]$csi[Left]$csi[suffix]    backward-char
bindkey $csi[base]$csi[Right]$csi[suffix]   forward-char
bindkey $csi[base]$csi[Up]$csi[suffix]      up-line-or-beginning-search
bindkey $csi[base]$csi[Down]$csi[suffix]    down-line-or-beginning-search

# Binds Alt-Arrows to the smart word-jump widgets
bindkey $csi[base]$csi[AltLeft]             backward-word
bindkey $csi[base]$csi[AltRight]            forward-word

unset csi # Clean up the temporary array

# +------------------------+
# |  CUSTOM WIDGET BINDS   |
# +------------------------+

# Bind the '.' key to the custom '_zsh-dot' widget.
# This widget provides "smart dot" expansion (e.g., '..' -> '../..').
bindkey . _zsh-dot

# Bind the spacebar to the custom '_expand-alias' widget.
# This expands any alias on the line *before* executing,
# allowing you to see what command you're *really* running.
bindkey ' ' _expand-alias

# +----------------------+
# |  PLUGIN KEYBINDINGS  |
# +----------------------+

# --- Robust History Search ---
# Bind standard arrow keys to the same "search" widgets.
# This ensures history search works everywhere, even if CSI u isn't active.
# ${terminfo[kcuu1]} is the terminfo-safe way to say "Up-Arrow".
# ${terminfo[kcud1]} is the terminfo-safe way to say "Down-Arrow".
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# Bind Ctrl+Space to accept the currently-shown suggestion.
# '^ ' is the Zsh notation for Ctrl+Space.
bindkey '^ ' autosuggest-accept