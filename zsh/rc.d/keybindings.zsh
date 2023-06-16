# +--------------+
# | Key Bindings |
# +--------------+

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

zmodload zsh/terminfo

# Create a zkbd compatible hash
# typeset -A key
# key[Delete]=$terminfo[kdch1]
# key[Up]=$terminfo[kcuu1]
# key[Down]=$terminfo[kcud1]
# key[Backspace]=$terminfo[kbs]

# # Setup keys accordingly
# # [[ -n $key[Delete]    ]] && bindkey $key[Delete]     delete-char
# [[ -n $key[Backspace] ]] && bindkey $key[Backspace]  backward-delete-char

# Make dot key autoexpand "..." to "../.." and so on
_zsh-dot () {
    if [[ $LBUFFER = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}

zle -N _zsh-dot
bindkey . _zsh-dot

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( $+terminfo[smkx] && $+terminfo[rmkx] )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
