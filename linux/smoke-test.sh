#!/usr/bin/env bash
# Lightweight smoke test for deploy.sh — run on the VM after deploying,
# e.g. `make smoke-test`. Checks the cheap, high-signal stuff (binaries
# present, expected packages/themes registered) rather than trying to
# assert interactive/visual behavior (prompt rendering, keybindings,
# zellij TUI rendering). Those don't test reliably over a non-interactive
# SSH session anyway — a real terminal is needed for TTY-dependent
# features, and a scripted check can't tell "genuinely broken" apart from
# "no TTY in this test harness".
set -uo pipefail

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

failures=0

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  ok    %s\n' "$desc"
  else
    printf '  FAIL  %s\n' "$desc"
    failures=$((failures + 1))
  fi
}

echo "Binaries:"
for bin in zsh bat delta doggo dua curlie fd rg jaq tldr htop eza zoxide direnv nvim zellij fzf xclip git curl wget gpg; do
  check "$bin" command -v "$bin"
done

echo "apt package state:"
check "zsh installed (dpkg)" bash -c "dpkg -l zsh | grep -q '^ii'"
check "tealdeer installed (dpkg)" bash -c "dpkg -l tealdeer | grep -q '^ii'"

echo "bat theme:"
check "Catppuccin Mocha registered" bash -c "bat --list-themes | grep -qi 'catppuccin mocha'"

# Single-quoted bash -c bodies below are deliberate: expansion happens in
# the child shell (which inherits the exported XDG_*/HOME vars above), not
# here.
echo "Config symlinks:"
# shellcheck disable=SC2016
check ".zshenv linked" bash -c '[[ -L $HOME/.zshenv && -e $HOME/.zshenv ]]'
# shellcheck disable=SC2016
check "nvim init.lua linked" bash -c '[[ -L $XDG_CONFIG_HOME/nvim/init.lua && -e $XDG_CONFIG_HOME/nvim/init.lua ]]'
# shellcheck disable=SC2016
check "claude/rules linked" bash -c '[[ -L $XDG_CONFIG_HOME/claude/rules && -e $XDG_CONFIG_HOME/claude/rules ]]'

echo "Shell:"
# shellcheck disable=SC2016
check "zsh is the default login shell" bash -c '[[ "$(getent passwd "$(id -un)" | cut -d: -f7)" == "$(command -v zsh)" ]]'

echo "Ghostty terminfo:"
# shellcheck disable=SC2016
check "xterm-ghostty registered" bash -c 'TERMINFO="$XDG_DATA_HOME/terminfo" infocmp xterm-ghostty'

echo
if [[ $failures -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "$failures check(s) failed."
  exit 1
fi
