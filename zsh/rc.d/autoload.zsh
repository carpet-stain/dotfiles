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

# run ls when cd into a directory
_chpwd_ls() {
  eza --icons --group-directories-first --all
}

add-zsh-hook chpwd _chpwd_ls

# Highlight use of sudo
_highlight_sudo() {
  if [[ "$1" == sudo* ]]; then
    echo "⚠️ Running as root: $1"
  fi
}

add-zsh-hook preexec _highlight_sudo

# Custom personal functions
# Don't use -U as we need aliases here
autoload -z evalcache compdefcache rgf