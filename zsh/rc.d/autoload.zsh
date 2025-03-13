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

# Load custom functions
autoload -Uz _zsh-dot _expand-alias _sesh-sessions _highlight-sudo _chpwd-eza _zsh-cursor-shape-reset _zsh-cursor-shape-ibeam

zle -N _zsh-dot
zle -N _expand-alias
zle -N _sesh-sessions
zle -N _highlight-sudo
zle -N _chpwd-eza
zle -N _zsh-cursor-shape-ibeam
zle -N _zsh-cursor-shape-reset

# Ensure add-zsh-hook is loaded
autoload -Uz add-zsh-hook

add-zsh-hook chpwd _chpwd-eza
add-zsh-hook preexec _highlight-sudo
add-zsh-hook preexec _zsh-cursor-shape-reset
add-zsh-hook precmd _zsh-cursor-shape-ibeam

# Don't eat space after '<Tab>' followed by '&' or '|'
ZLE_SPACE_SUFFIX_CHARS="&|"

# Eat space after '<Tab>' followed by ')', etc.
ZLE_REMOVE_SUFFIX_CHARS=" \t\n;)"

