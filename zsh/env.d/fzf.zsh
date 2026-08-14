#!/usr/bin/env zsh

# fzf configuration: default command, theme, layout/behavior opts, and the
# Ctrl+T / Ctrl+R / Alt+C bindings. Extracted from .zshenv (was the only
# other tool block that size with its own darwin/linux branching, alongside
# ls_colors.zsh) so .zshenv stays focused on its bootstrap/XDG/PATH spine.

export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"

# Colors from the catppuccin/fzf submodule (sets FZF_DEFAULT_OPTS); mode
# selected by THEME_MODE (derived in .zshenv)
if [[ $THEME_MODE == light ]]; then
  source $DOTFILES/theme/fzf/themes/catppuccin-fzf-latte.sh
else
  source $DOTFILES/theme/fzf/themes/catppuccin-fzf-mocha.sh
fi

# Append layout and behavior on top of the theme's colors
FZF_DEFAULT_OPTS+="
  --color header:italic
  --scrollbar '▋'
  --layout reverse
  --info right
  --prompt ' : '
  --pointer ''
  --marker '✓'
  --preview-window 'right:65%'
  --ansi"

# These flags need fzf 0.66+; both platforms clear that (#442), but the popup/border
# rendering is only verified in a macOS terminal — darwin-only until checked on Linux.
if [[ $OSTYPE == darwin* ]]; then
  # --border: fzf 0.74.0+ only draws its own popup frame when a style is explicit,
  # else Zellij's pane border takes over, clashing with `pane_frames false` (#195).
  FZF_DEFAULT_OPTS+="
  --popup=90%
  --highlight-line
  --input-border
  --border
  --ghost='Type to search...'
  --gutter=' '"
else
  # fzf 0.74.1 auto-hides the info separator when a border already splits input from
  # list, so it's redundant on darwin but still needed here — no border set (#383).
  FZF_DEFAULT_OPTS+="
  --no-separator"
fi

# Ctrl+T — file search
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
if [[ $OSTYPE == darwin* ]]; then
  export FZF_CTRL_T_OPTS="
    --border-label ' 󰱽 File Search '
    --preview 'bat {}'
    --header '📌 ⌃O to Open | ⌃Y to Copy | ⌃E to Edit'
    --bind 'ctrl-o:become(open -R {})'
    --bind 'ctrl-y:become(echo -n {} | $CLIPBOARD_COPY)'
    --bind 'ctrl-e:become(zellij action new-tab -- $EDITOR {+} >/dev/null)'
    --select-1 --exit-0"

  export FZF_CTRL_R_OPTS="
    --border-label ' 󰱽 Command History '
    --preview 'echo {2..} | bat -l bash --plain --color always'
    --preview-window 'down:3:wrap:border-top'
    --bind 'ctrl-y:become(echo -n {2..} | $CLIPBOARD_COPY)'
    --header '⌃Y Copy'
    --nth 2..
    --color 'nth:regular,fg:dim'"
else
  export FZF_CTRL_T_OPTS="
    --border-label ' 󰱽 File Search '
    --preview 'bat {}'
    --header '⌃Y to Copy | ⌃E to Edit'
    --bind 'ctrl-y:become(echo -n {} | $CLIPBOARD_COPY)'
    --bind 'ctrl-e:become(zellij action new-tab -- $EDITOR {+} >/dev/null)'
    --select-1 --exit-0"

  export FZF_CTRL_R_OPTS="
    --border-label ' 󰱽 Command History '
    --preview 'echo {2..} | bat -l bash --plain --color always'
    --preview-window 'down:3:wrap:border-top'
    --bind 'ctrl-y:become(echo -n {2..} | $CLIPBOARD_COPY)'
    --header '⌃Y Copy'
    --nth 2..
    --color 'nth:regular,fg:dim'"
fi

# Alt+C — directory jump
export FZF_ALT_C_COMMAND="fd --type d --strip-cwd-prefix --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="
  --border-label ' 󰱽 Directory Explorer '
  --preview '$EZACMD --tree --level=2 {}'"
