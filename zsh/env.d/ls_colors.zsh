#!/usr/bin/env zsh

# Colorizes zsh's own completion listings (rc.d/completions.zsh) and fzf-tab's
# bundled zsh-ls-colors library — both read LS_COLORS directly, independent of
# eza (which has its own theme, see theme/eza and the EZA block in .zshenv).
#
# THEME_MODE (derived in .zshenv) selects which pre-generated blob to export —
# see ls_colors-mocha.zsh/ls_colors-latte.zsh for how to regenerate either one.
if [[ $THEME_MODE == light ]]; then
  source $ZDOTDIR/env.d/ls_colors-latte.zsh
else
  source $ZDOTDIR/env.d/ls_colors-mocha.zsh
fi
