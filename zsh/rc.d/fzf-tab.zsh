#!/usr/bin/env zsh

# Source the fzf-tab plugin from its submodule location
source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

# +------------------------+
# |  GENERAL FZF-TAB SETTINGS  |
# +------------------------+

# This is a great non-default setting:
# It makes fzf-tab re-trigger on <space> as well as <tab>.
# e.g., `git <space>` (shows subcommands) `commit <space>` (shows --options)
zstyle ':fzf-tab:*'            continuous-trigger   space

# Remap keys *inside* the fzf menu for convenience.
zstyle ':fzf-tab:*'            fzf-bindings         'tab:down' 'shift-tab:up' 'enter:accept'

# Automatically accept the selection on 'enter'.
zstyle ':fzf-tab:*'            accept-line          enter

# Set keys to switch between completion groups (e.g., "commands" vs "aliases")
zstyle ':fzf-tab:*'            switch-group         '<' '>'

# Simple preview for user-defined expansions (e.g., zstyle_expand)
zstyle ':fzf-tab:user-expand:' fzf-preview          'less $word'

# Manually set the Catppuccin theme (copied from FZF_DEFAULT_OPTS)
# This avoids using 'use-fzf-default-opts' which breaks tmux layout

# Define flags as a Zsh array. This is the robust way to handle
# arguments with spaces or special characters, preventing them
# from being misinterpreted as completion candidates.
typeset -a fzf_theme_flags
fzf_theme_flags=(
  '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8'
  '--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc'
  '--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'
  '--color=selected-bg:#45475a'
  '--color=border:#313244,label:#cdd6f4'
  '--color=header:italic'
  '--border=rounded'
  '--border-label-pos=center'
)

# Pass the array of flags to the zstyle.
zstyle ':fzf-tab:*' fzf-flags $fzf_theme_flags

# Clean up the temporary array
unset fzf_theme_flags

# +----------------------+
# |  PREVIEW GENERATION  |
# +----------------------+

# This is a complex preview generator for general command completions.
# The glob '(-command-:|command:option-(v|V)-rest)' targets:
#   1. '-command-': Any command name.
#   2. 'command:option-(v|V)-rest': Arguments *after* a -v or -V flag.
#
# It uses a case statement on the $group variable (provided by zsh's completion)
# to show different previews for different *types* of completions.
zstyle ':fzf-tab:complete:(-command-:|command:option-(v|V)-rest)' fzf-preview \
    'case $group in
        "external command")
            # For external commands, use `less =$word`
            # The `less =<file>` syntax searches $PATH for the file.
            which $word && less =$word
        ;;
        "executable file")
            # For local files, just `less` the real path.
            which $word && less ${realpath#--*=}
        ;;
        "builtin command")
            # For zsh builtins, pipe the `run-help` output to `bat`.
            run-help $word | bat -plman
        ;;
        "parameter")
            # For variables, preview their *value*.
            # ${(P)word} is a Zsh "Parameter" expansion flag.
            # It treats the value of $word as a *new variable name*
            # and expands that. e.g., if $word is "HOME", it runs `echo $HOME`.
            echo ${(P)word}
        ;;
    esac'

# This provides the same variable-preview functionality as above,
# but specifically for commands like `export`, `unset`, etc.
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
    'echo ${(P)word}'

# Directory content preview with eza for `cd`
# '$realpath' is a variable provided by fzf-tab pointing to the selected item.
# 'eval' is used to correctly expand the $EZACMD variable (which contains spaces/flags).
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eval $EZACMD --tree --level=1 -I .git $realpath'

# --- Git Previews ---

# Preview the log history when completing 'git checkout' or 'git switch'
zstyle ':fzf-tab:complete:git-(checkout|switch):*' fzf-preview \
  'git log --oneline --graph --decorate --color=always HEAD.."$word"'

# Preview the diff when completing 'git log' (e.g., fuzzy-finding a commit hash)
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git show --color=always $word'

# --- Kill Preview ---
# (This works with the zstyle in completions.zsh that provides the command names)
# Show detailed `ps -f` (full-format) info for the selected PID.
zstyle ':fzf-tab:complete:kill:*' fzf-preview \
  'ps -f -p $word'

# --- SSH Preview ---
# (This works with the zstyle in completions.zsh that reads ssh config)
# Preview the SSH config block for the selected host.
# `grep -A 10` shows the host line and the 10 lines *after* it.
zstyle ':fzf-tab:complete:(ssh|scp):*' fzf-preview \
  "grep -A 10 -i \"^Host $word\" ~/.ssh/config | bat --language=ssh_config"