#!/usr/bin/env zsh

autoload -Uz colors
colors

# Alt-Left/Right word navigation
autoload -Uz forward-word backward-word
zle -N forward-word
zle -N backward-word

# Ctrl+W stops at path delimiters instead of deleting the whole path
autoload -Uz select-word-style
select-word-style bash

# Auto-quote special characters when pasting URLs
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# Paste multi-line text as one block instead of auto-executing each line
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Speeds up pasting: skip paste-magic handling for everything but self-insert
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# Search-as-you-type history on Up/Down
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search

# Custom widgets from fpath/ — filename must match the function name
autoload -Uz \
  _zsh-dot \
  _expand-alias \
  _chpwd-eza \
  _zsh-cursor-shape-reset \
  _zsh-cursor-shape-ibeam

zle -N _zsh-dot
zle -N _expand-alias
zle -N _chpwd-eza
zle -N _zsh-cursor-shape-ibeam
zle -N _zsh-cursor-shape-reset

autoload -Uz add-zsh-hook

# +-------+
# | HOOKS |
# +-------+

add-zsh-hook chpwd _chpwd-eza
add-zsh-hook preexec _zsh-cursor-shape-reset
add-zsh-hook precmd _zsh-cursor-shape-ibeam

# +-----+
# | ZLE |
# +-----+

# Don't eat space after '<Tab>' followed by '&' or '|'
ZLE_SPACE_SUFFIX_CHARS="&|"

# Eat space after '<Tab>' followed by ')', etc.
ZLE_REMOVE_SUFFIX_CHARS=" \t\n;)"

# Removes the syntax highlighting "flash" when pasting text
zle_highlight+=(paste:none)
