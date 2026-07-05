#!/usr/bin/env zsh

# +------------------+
# |  SAFETY ALIASES  |
# +------------------+

# Prevent 'chown' from recursively changing permissions on the root directory.
alias chown="chown --preserve-root"

# '-i' (interactive) prompts for confirmation before overwriting.
alias cp="cp -i --verbose"
alias ln="ln -i"
alias mv="mv -i"

# Use '-I' (prompt once before removing more than three files) instead of '-i' (which prompts
# for every file) for a safer, but less annoying, 'rm'.
# '--preserve-root=all' prevents recursive removal of '/'.
# https://github.com/sindresorhus/guides/blob/main/how-not-to-rm-yourself.md#safeguard-rm
alias rm="rm -I --preserve-root=all"

# '-pv' creates parent directories as needed and is verbose about what it's doing.
alias mkdir="mkdir -pv"

# +------------------------+
# |  MODERN REPLACEMENTS   |
# +------------------------+

# Use 'bat' (with no paging or decorations) as a drop-in 'cat' replacement.
alias cat="bat -p"
# Use 'delta' for 'diff'. (Configured in gitconfig)
alias diff="delta"
# Use 'doggo' as a 'dig' replacement.
alias dig="doggo"
# Use 'dua' as a 'du' replacement.
alias du="dua"
alias dui="dua interactive"
# Use 'curlie' as a 'curl' replacement (easier for JSON/headers).
alias curl="curlie"
# Use 'fd' as a 'find' replacement.
alias find="fd"
# Use the '$EZACMD' variable (defined in .zshenv) for 'ls'.
# 'command' prefix prevents this alias from looping on itself.
alias ls="command $EZACMD"
# Re-use '$EZACMD' to create a 'tree' alias.
alias tree="$EZACMD --tree --level=2 -I .git"
# Replace grep with ripgrep (rg)
alias grep="rg"
# Get "help" from tldr (tealdeer)
alias help="tldr"

# +---------------------+
# |  QoL & UTILITIES   |
# +---------------------+

# Ensure 'tmux' *always* loads our custom config file.
alias tmux="tmux -f $DOTFILES/tmux/tmux.conf"

# 'df -h' is for "human-readable" disk free space.
alias df="df -h"
# Make 'mount' output much cleaner by piping it to 'column -t'.
alias mount="mount | column -t"

# Use Zsh's 'print -P' with ANSI-C quoting to ensure \n is interpreted correctly.
# The `\n` character must be expanded *after* the colon replacement.
alias path="print -P \${(j:\n:)path}"
alias fpath="print -P \${(j:\n:)fpath}"

# Reload the shell by replacing the current shell process ('exec')
# with a new login shell ('-l'), which re-sources all configs.
alias reload="exec $SHELL -l"
alias vim="nvim"
alias vi="nvim"

# Quick public IP check using OpenDNS and doggo
alias ip="doggo +short myip.opendns.com @resolver1.opendns.com"

# +-----------------+
# |  GLOBAL ALIASES |
# +-----------------+

# These are "global aliases" ('-g'), which work anywhere on the command line,
# not just at the start.
#
# `2>&1 | bat ...` is the core:
#   '2>&1' -> Redirects stderr (where help is often printed) to stdout.
#   '| bat' -> Pipes the combined output to 'bat' for syntax highlighting.
#
# The result: Any command ending in ' --help'
# (e.g., `curl --help`) will be automatically colorized.
alias -g -- --help="--help 2>&1 | bat --language=help --style=plain"