#!/usr/bin/env zsh

# Zstyle pattern
# :completion:<function>:<completer>:<command>:<argument>:<tag>

zstyle :completion:*                  list-colors         ${(s.:.)LS_COLORS}

# Define completers
zstyle :completion:*                  completer           _expand _complete _ignored _approximate

# Use cache for commands using cache
zstyle :completion:*                  use-cache           on
zstyle :completion:*                  cache-path          "$XDG_CACHE_HOME/zsh/zcompcache"

zstyle :completion:*                  list-dirs-first     on
zstyle :completion:*                  matcher-list        '' 'm:{[:lower:]}={[:upper:]}'

# Display descriptions and corrections in a custom format
zstyle :completion:*:descriptions     format              '[%d]'
zstyle :completion:*:corrections      format              '[%d]'
zstyle :completion:*:manuals          separate-sections   true

# disable sort when completing options of any command
zstyle :completion:complete:*:options sort                false

# Allow you to select in a menu
zstyle :completion:*                  menu                select

# Autocomplete options for cd instead of directory stack
zstyle :completion:*                  complete-options    true

# Only display some tags for the command cd
zstyle :completion:*                  tag-order           '! users'

# To group the different type of matches under their descriptions
zstyle :completion:*                  group-name          ''

zstyle :completion:*:*:-command-:*:*  group-order         aliases builtins functions commands

zstyle :completion:*                  keep-prefix         true

zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts '
  reply=(
    ${=${${(f)"$(cat ~/.ssh/config /etc/ssh_config /etc/ssh/ssh_config ~/.ssh/known_hosts(|2)(N) /dev/null)"}%%[# ]*}//,/}
  )
'
# Add completion paths
fpath+=( 
    $XDG_CACHE_HOME/zsh/fpath(N)
    $HOMEBREW_PREFIX/share/zsh-completions
    $HOMEBREW_PREFIX/share/zsh/site-functions
)

# Make sure complist is loaded
zmodload zsh/complist

# Init completions, but regenerate compdump only once a day.
# The globbing is a little complicated here:
# - '#q' is an explicit glob qualifier that makes globbing work within zsh's [[ ]] construct.
# - 'N' makes the glob pattern evaluate to nothing when it doesn't match (rather than throw a globbing error)
# - '.' matches "regular files"
# - 'mh+20' matches files (or directories or whatever) that are older than 20 hours.
autoload -Uz compinit

if [[ -n $XDG_CACHE_HOME/zsh/compdump(#qN.mh+20) ]]; then
    compinit -i -u -d $XDG_CACHE_HOME/zsh/compdump
    # zrecompile fresh compdump in background
    {
        autoload -Uz zrecompile
        zrecompile -pq $XDG_CACHE_HOME/zsh/compdump
    } &!
else
    compinit -i -u -C -d $XDG_CACHE_HOME/zsh/compdump
fi

# Enable bash completions too
autoload -Uz bashcompinit && bashcompinit