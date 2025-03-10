#!/usr/bin/env zsh

source $ZDOTDIR/plugins/fzf-tab/fzf-tab.zsh

# General fzf-tab Settings
zstyle ':fzf-tab:*'            continuous-trigger   space
zstyle ':fzf-tab:*'            fzf-bindings         'tab:down' 'shift-tab:up' 'enter:accept'
zstyle ':fzf-tab:*'            accept-line          enter
zstyle ':fzf-tab:*'            switch-group         '<' '>'

# To make fzf-tab follow FZF_DEFAULT_OPTS.
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# User expand
zstyle ':fzf-tab:user-expand:' fzf-preview          'less $word'

# Command completion preview
zstyle ':fzf-tab:complete:(-command-:|command:option-(v|V)-rest)' fzf-preview \
    'case $group in
        "external command")
            which $word && less =$word
        ;;
        "executable file")
            which $word && less ${realpath#--*=}
        ;;
        "builtin command")
            run-help $word | bat -plman
        ;;
        "parameter")
            echo ${(P)word}
        ;;
    esac'

# Parameter completion preview
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
'echo ${(P)word}'

# Directory content preview with eza for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --group-directories-first -a --color=always --dereference $realpath' # remember to use single quote here!!
