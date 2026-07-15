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
alias dig="doggo"
alias du="dua"
alias dui="dua interactive"
# curlie: curl with easier JSON/headers
alias curl="curlie"
alias find="fd"
# Use the '$EZACMD' variable (defined in .zshenv) for 'ls'.
alias ls="$EZACMD"
alias tree="$EZACMD --tree --level=2 -I .git"
alias grep="rg"
# jaq: faster jq
alias jq="jaq"
# tldr is tealdeer's binary name
alias help="tldr"
alias top="htop"
# dysk: df that dedupes noisy system volumes, no '-h' needed
alias df="dysk"
alias ps="procs"
# viddy: watch replacement (macOS ships no 'watch' by default)
alias watch="viddy"

# +---------------------+
# |  QoL & UTILITIES   |
# +---------------------+

# Make 'mount' output much cleaner by piping it to 'column -t'.
alias mount="mount | column -t"

# Use Zsh's 'print -P' with ANSI-C quoting to ensure \n is interpreted correctly.
# The `\n` character must be expanded *after* the colon replacement.
alias path="print -P \${(j:\n:)path}"
alias fpath="print -P \${(j:\n:)fpath}"
alias manpath="print -P \${(j:\n:)manpath}"

# Reload the shell by replacing the current shell process ('exec')
# with a new login shell ('-l'), which re-sources all configs.
alias reload="exec $SHELL -l"
alias vim="nvim"
alias vi="nvim"

# Quick public IP check using OpenDNS and doggo
alias ip="doggo +short myip.opendns.com @resolver1.opendns.com"

# +----------------+
# |  BATCH RENAME  |
# +----------------+

# 'zmv' is a zsh builtin module for pattern-based batch rename/copy/link.
# e.g. `zmv '(*).log' '$1.txt'` renames every .log file to .txt.
autoload -Uz zmv
alias zcp="zmv -C"   # copy-mode:  batch copy by pattern
alias zln="zmv -L"   # link-mode:  batch hard-link by pattern

# +-----------------+
# |  GLOBAL ALIASES |
# +-----------------+

# Global aliases ('-g') expand anywhere on the line — that's what lets a
# trailing ' --help' rewrite itself to pipe through bat. '2>&1' folds in
# stderr, where many tools print their help.
alias -g -- --help="--help 2>&1 | bat --language=help --style=plain"

# Pipe/redirect shorthands. Uppercase to avoid clashing with real commands,
# though as global aliases they still expand anywhere on the line.
# 'J' pipes to 'jq', which itself re-expands to 'jaq' via the alias above.
# 'C' uses the platform clipboard command resolved in .zshenv.
alias -g -- J="| jq"
alias -g -- C="| $CLIPBOARD_COPY"  # copy to clipboard (pbcopy/wl-copy/xclip)
alias -g -- F="| fzf"              # fuzzy-filter
alias -g -- NUL=">/dev/null 2>&1"  # silence stdout and stderr

# +------------------+
# |  SUFFIX ALIASES  |
# +------------------+

# Suffix alias ('-s') runs a bare filename through a handler by extension:
# typing 'data.json' becomes 'jq . < data.json' (jq -> jaq via alias above).
alias -s json="jq . <"