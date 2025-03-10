#!/usr/bin/env zsh

# Initialize colors
autoload -Uz colors
colors

# Enhanced word navigation
autoload -Uz forward-word backward-word
zle -N forward-word
zle -N backward-word

# Ctrl+W stops on path delimiters
autoload -Uz select-word-style
select-word-style bash

# enable url-quote-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# enable bracketed paste
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Use default provided history search widgets
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search

# Ensure add-zsh-hook is loaded
autoload -Uz add-zsh-hook

# run eza when cd into a directory
_chpwd_eza() {
  command eza --icons --group-directories-first -a --classify=auto --dereference
}

add-zsh-hook chpwd _chpwd_eza

# Highlight use of sudo
_highlight_sudo() {
  if [[ $1 == sudo* ]]; then
    echo "⚠️ Running as root: $1"
  fi
}

add-zsh-hook preexec _highlight_sudo

_zsh_cursor_shape_reset() {
    echoti Se
}

_zsh_cursor_shape_ibeam() {
    echoti Ss 6
}

add-zsh-hook preexec _zsh_cursor_shape_reset
add-zsh-hook precmd _zsh_cursor_shape_ibeam

# Don't eat space after '<Tab>' followed by '&' or '|'
ZLE_SPACE_SUFFIX_CHARS="&|"

# Eat space after '<Tab>' followed by ')', etc.
ZLE_REMOVE_SUFFIX_CHARS=" \t\n;)"


