# Initialize colors
autoload -U colors && colors

# URL magic
autoload -U url-quote-magic
zle -N self-insert url-quote-magic

# Fullscreen command line edit
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Ctrl+W stops on path delimiters
autoload -U select-word-style
select-word-style bash
