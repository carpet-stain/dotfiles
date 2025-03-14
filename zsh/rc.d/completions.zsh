#!/usr/bin/env zsh

# Zstyle pattern
# :completion:<function>:<completer>:<command>:<argument>:<tag>

# Set list-colors to enable filename colorizing
zstyle ':completion:*'                  list-colors         ${(s.:.)LS_COLORS}

# Define completers
zstyle ':completion:*'                  completer           _expand _complete _ignored _approximate

# Use cache for commands using cache
zstyle ':completion:*'                  use-cache           true
zstyle ':completion:*'                  cache-path          $XDG_CACHE_HOME/zsh/zcompcache

zstyle ':completion:*'                  list-dirs-first     on

# Additional matcher specifications to try one after the other until we have 1+ match.
# (They will all by tried for all completers)
# 1. 'm:{[:lower:]}={[:upper:]}' -> Case insensitive (low -> up) completions
# 2. '+r:|[-_:./]=**' -> [1.] + Allow '-_:./' chars to act similar to glob patterns
zstyle ':completion:*'                  matcher-list        'm:{[:lower:]}={[:upper:]}' '+r:|[-_:./]=**'

zstyle ':completion:*'                  add-space           true

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions'     format              '[%d]'
zstyle ':completion:*:corrections'      format              '[%d]'
zstyle ':completion:*:manuals'          separate-sections   true

# disable sort when completing options of any command
zstyle ':completion:complete:*:options' sort                false

# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*'                  menu                no

# Autocomplete options for cd instead of directory stack
zstyle ':completion:*'                  complete-options    true

# Only display some tags for the command cd
zstyle ':completion:*'                  tag-order           '! users'

# To group the different type of matches under their descriptions
zstyle ':completion:*'                  group-name          ''

zstyle ':completion:*:*:-command-:*:*'  group-order         aliases builtins functions commands

zstyle ':completion:*'                  keep-prefix         true

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*'   sort                false

# Speeds up pasting into terminal
zstyle ':bracketed-paste-magic'         active-widgets      '.self-*'

# Add completion paths
fpath+=$HOMEBREW_PREFIX/share/zsh-completions

# Make sure complist is loaded
zmodload zsh/complist

# Init completions, but regenerate compdump only once a day.
autoload -Uz compinit

# Use a glob qualifier to check if compdump is older than 20 hours
if REPLY=($XDG_CACHE_HOME/zsh/compdump(#qN.mh+20)); [[ -n $REPLY ]]; then
    # Initialize completions and update compdump
    nocorrect compinit -i -u -d $XDG_CACHE_HOME/zsh/compdump

    # Only recompile if compdump was updated
    if [[ -s "$XDG_CACHE_HOME/zsh/compdump" ]]; then
        autoload -Uz zrecompile
        zrecompile -pq $XDG_CACHE_HOME/zsh/compdump
    fi
else
    # Use compdump cache without regenerating
    nocorrect compinit -i -u -C -d $XDG_CACHE_HOME/zsh/compdump
fi

# Enable bash completions too
autoload -Uz bashcompinit && bashcompinit
