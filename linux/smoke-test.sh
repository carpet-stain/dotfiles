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

failures=0

check() {
  local desc="$1"; shift
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
check "zsh installed (dpkg)"      bash -c "dpkg -l zsh | grep -q '^ii'"
check "tealdeer installed (dpkg)" bash -c "dpkg -l tealdeer | grep -q '^ii'"

echo "bat theme:"
check "Catppuccin Mocha registered" bash -c "bat --list-themes | grep -qi 'catppuccin mocha'"

echo
if [[ $failures -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "$failures check(s) failed."
  exit 1
fi
