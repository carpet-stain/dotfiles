#!/usr/bin/env zsh

# This file configures and initializes Zsh's completion system (compinit).
# It's tuned for performance, fzf-tab, and smart matching.

# Zstyle pattern syntax:
# :completion:<function>:<completer>:<command>:<argument>:<tag>
# '*' is a wildcard for any field.

# Set list-colors to enable filename colorizing during completion.
# ${(s.:.)LS_COLORS} is a Zsh-specific parameter expansion:
#   's.:.' -> Splits the $LS_COLORS variable by the ':' delimiter.
# This correctly passes the color list to the 'list-colors' zstyle.
zstyle ':completion:*'                  list-colors         ${(s.:.)LS_COLORS}

# Define the order of completion methods (completers) Zsh should try.
# _expand:       Performs glob expansions.
# _complete:     The main completion engine.
# _ignored:      Completes ignored patterns (e.g., files in .gitignore).
# _approximate:  Tries to find approximate/misspelled matches.
zstyle ':completion:*'                  completer           _expand _complete _ignored _approximate

# Use a cache for completion results to speed up subsequent completions.
zstyle ':completion:*'                  use-cache           true
zstyle ':completion:*'                  cache-path          $XDG_CACHE_HOME/zsh/zcompcache

# When listing completions, show directories before files.
zstyle ':completion:*'                  list-dirs-first     on

# This is the "magic" matching configuration.
# Zsh tries matchers in this list until one succeeds.
# 1. 'm:{[:lower:]}={[:upper:]}'
#    'm:' -> A 'match' specification.
#    '{[:lower:]}={[:upper:]}' -> Match lower-case input with upper-case equivalents (case-insensitive).
#
# 2. '+r:|[-_:./]=**'
#    '+' -> This is *not* a new matcher, but a prefix for the *previous* one.
#    'r:' -> Enables remote matching (e.g., 'f/b/z' matches 'foo/bar/baz').
#    '|[-_:./]=**' -> Allows characters in the brackets to match any sequence (like '**').
#    Example: 'm_f' could match 'my_file' or 'my-file' or 'my.file'.
zstyle ':completion:*'                  matcher-list        'm:{[:lower:]}={[:upper:]}' '+r:|[-_:./]=**'

# Automatically add a space after a completed word.
zstyle ':completion:*'                  add-space           true

# Format descriptions, corrections, and manuals with brackets. E.g., "[directory]"
zstyle ':completion:*:descriptions'     format              '[%d]'
zstyle ':completion:*:corrections'      format              '[%d]'
zstyle ':completion:*:manuals'          separate-sections   true

# Disable sorting for command options (like -h, -v, -f).
# This is faster and often more logical (e.g., shows short/long forms together).
zstyle ':completion:complete:*:options' sort                false

# CRITICAL: This is the integration for fzf-tab.
# 'menu no' disables Zsh's built-in completion menu entirely,
# allowing fzf-tab to launch and take control of the UI instead.
zstyle ':completion:*'                  menu                no

# When completing 'cd', complete command-line options (like 'cd -')
# in addition to directory names.
zstyle ':completion:*'                  complete-options    true

# When completing 'cd', don't show the "users" tag (home directories).
zstyle ':completion:*'                  tag-order           '! users'

# Group completions by their type (e.g., "aliases", "commands").
zstyle ':completion:*'                  group-name          ''

# Define the order in which to display completion groups.
zstyle ':completion:*:*:-command-:*:*'  group-order         aliases builtins functions commands

# When completing, keep the prefix I've already typed.
zstyle ':completion:*'                  keep-prefix         true

# Speeds up pasting into the terminal by disabling special
# paste-magic handling for most widgets, only keeping it for self-insert.
zstyle ':bracketed-paste-magic'         active-widgets      '.self-*'

# +--------------------------------+
# | APPLICATION-SPECIFIC ZSTYLES   |
# +--------------------------------+

# --- Git Completions ---
# Don't sort 'git checkout' results (faster, shows recent branches first).
zstyle ':completion:*:git-checkout:*'   sort                false
# Complete tags as well as branches for checkout/switch.
zstyle ':completion:*:git-checkout:*'  complete-refs 'yes'
zstyle ':completion:*:git-switch:*'    complete-refs 'yes'
# Show verbose descriptions for git aliases.
zstyle ':completion:*:git:*'           verbose 'yes'

# --- Kill Completions ---
# Show full command lines for 'kill' targets instead of just PIDs.
# This feeds rich data directly into fzf-tab.
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,command | sed "s/ $//"'
zstyle ':completion:*:kill:*' table-format 'PID:8' 'COMMAND'
zstyle ':completion:*:kill:*' sort-order 'user'

# --- SSH Completions ---
# Read SSH config and known_hosts for hostname completion.
zstyle ':completion:*:ssh:*:*' hosts-file ~/.ssh/config ~/.ssh/known_hosts

# +----------------------+
# |  COMPLETION SYSTEM   |
# +----------------------+

# Add Homebrew's completions to the function path.
fpath+=$HOMEBREW_PREFIX/share/zsh-completions

# Load the 'complist' module, which provides extended completion list formatting.
zmodload zsh/complist

# Initialize the completion system.
autoload -Uz compinit
local compdump_file="$XDG_CACHE_HOME/zsh/compdump"

# This block is for performance:
# It checks if the compdump file *exists* AND is *older than 20 hours*.
#
# `($compdump_file(#qN.mh+20))` is a glob qualifier:
#   #q -> Quiet
#   N  -> NULL_GLOB (return nothing if no match, prevents error)
#   .  -> Plain files only
#   mh -> Modified time, in hours
#   +20 -> More than 20 hours ago
#
# `[[ -n ... ]]` checks if the result of that glob is "not empty".
#
if ! [[ -f "$compdump_file" ]] || [[ -n "($compdump_file(#qN.mh+20))" ]]; then
    # If file is missing or old, regenerate it.
    # 'nocorrect' prevents alias correction on the compinit command itself.
    # '-i' (insecure) skips security checks (we trust our own fpath).
    # '-u' (user) uses user's compdump file.
    # '-d' specifies the dump file path.
    nocorrect compinit -i -u -d "$compdump_file"
else
    # If the compdump is fresh, load it directly from cache ('-C').
    nocorrect compinit -i -u -C -d "$compdump_file"
fi

# Pre-compile the compdump file into a '.zwc' file.
# Zsh loads the binary '.zwc' file *much* faster than parsing the text compdump.
# 'zrecompile' is smart and will skip if the .zwc is already up-to-date.
autoload -Uz zrecompile
zrecompile -pq "$compdump_file"

# Load the bash completion compatibility system as a fallback
# for tools that don't provide native Zsh completions.
autoload -Uz bashcompinit && bashcompinit