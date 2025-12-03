#!/usr/bin/env zsh

# Load the fzf theme directly from the maintained repo
source $DOTFILES/theme/fzf/themes/catppuccin-fzf-mocha.sh

# Use 'ripgrep' as the default file-finder for FZF; it's much faster than 'find'.
export FZF_DEFAULT_COMMAND="rg --files"

# We use the Zsh multi-line append += operator to avoid breaking the sourced variable.
FZF_DEFAULT_OPTS+="
  --style=full
  --ansi
  --border=rounded
  --border-label-pos=center
  --layout=reverse
  --info=right
  --prompt=' : '
  --pointer=''
  --marker='✓'
  --preview-window='right:65%,wrap'
  --scrollbar='▋ '
  --no-separator
  --preview-label=' Preview '
  --preview-label-pos=center
  --preview-border=rounded  
  --tiebreak=pathname,length
  --ghost='Type to search...'
  --tmux 90%
  --gutter=' '"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

# 'become' replaces the fzf process with the new command.
# '{+1}' is fzf syntax for 'all selected items, starting from the first'.
export FZF_CTRL_T_OPTS="
  --border-label '  File Search '
  --preview 'bat {}'
  --header '📌 ⌃O Open | ⌃Y Copy | ⌃E Edit (Tab to multi-select)'
  --multi
  --bind 'multi:transform-header:(( FZF_SELECT_COUNT )) && echo \"📌 Selected \$FZF_SELECT_COUNT file(s)\"'
  --bind 'ctrl-o:become(open -R {+})'
  --bind 'ctrl-y:become(echo -n {+} | pbcopy)'
  --bind 'ctrl-e:become(tmux new-window $EDITOR -p {+1})'
  --select-1 --exit-0 # --select-1: select one item / --exit-0: exit on selection
  --tiebreak=pathname,length # Prioritize filename matches
  "

# For history, the fzf line is "INDEX TIMESTAMP COMMAND".
# '{2..}' is fzf syntax to select all fields *from the second one onwards*,
# which correctly grabs just the command.
export FZF_CTRL_R_OPTS="
  --border-label ' 󰋚 Command History '
  --bind 'ctrl-y:become(echo -n {2..} | pbcopy)'
  --bind 'up:up-match,down:down-match'
  --header '📌 ⌃Y to Copy | ⌃R Raw Mode'
  --nth=2..
  --color=nth:regular,fg:dim" # Highlight command, dim the rest 

# Use 'fd' (find directory) for Alt-C. 
# -t d: Find directories only
# -H:   Search hidden directories (like .config)
# -E:   Exclude .git to keep it clean
export FZF_ALT_C_COMMAND="fd --color=always -t d -H -E .git"

export FZF_ALT_C_OPTS="
  --border-label '   Directory Explorer '
  --preview '$EZACMD --tree --level=2 -I .git {}'
  "
