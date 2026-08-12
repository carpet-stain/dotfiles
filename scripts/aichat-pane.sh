#!/usr/bin/env bash
# Launcher for the Alt-a floating aichat pane (#511): resolve the OpenRouter
# key, map the theme, exec aichat. A wrapper exists only because the zellij
# server's environment never sees repo-scoped direnv exports and the key must
# stay process-scoped, not ambient — credential fetch + exec, no REPL logic.
#
# Key resolution: an already-set OPENROUTER_API_KEY wins (escape hatch); else
# the macOS login Keychain item `openrouter-api-key`, matched on service and
# account both so a same-named item under another account can't be picked up.
# The item is added with -A — silent reads are intentional: the key is
# routine-tier on a personal machine, the same trust class as
# `infra-aws-local-read` (aws-vended-token.sh), unlike infra's prompt-gated
# crown-jewel items. Residency is pending infra#170; moving to SSM later is a
# swap of the Keychain read below.
set -euo pipefail

# The pane runs with close_on_exit (config.kdl), so a missing dependency
# warns, waits for one keypress (Esc and Ctrl-c work too), and exits clean —
# the pane closes and the user is back in the terminal, no held error pane.
warn_and_close() {
  printf '%s\n' "$@" >&2
  printf '\npress any key to close\n' >&2
  read -rsn1 || true
  exit 0
}

command -v aichat >/dev/null || warn_and_close \
  "aichat-pane: aichat not installed — brew install aichat (Brewfile.payload); no Linux path yet (#511)"

if [[ -z ${OPENROUTER_API_KEY:-} ]]; then
  if ! OPENROUTER_API_KEY=$(security find-generic-password -s openrouter-api-key -a openrouter -w 2>/dev/null); then
    warn_and_close \
      "aichat-pane: no OPENROUTER_API_KEY in env and no Keychain item 'openrouter-api-key'." \
      "One-time setup (mint a key at openrouter.ai/settings/keys first):" \
      "  security add-generic-password -s openrouter-api-key -a openrouter -A -U -w" \
      "See AGENTS.md's Credentials section."
  fi
  export OPENROUTER_API_KEY
fi

# aichat 0.30 derives the key's env name from the client *type*, not its
# name: field — OPENAI_COMPATIBLE_API_KEY sends the header, OPENROUTER_API_KEY
# is never read (verified empirically against api.openrouter.ai; the wiki's
# {client}_API_KEY doc doesn't hold for this client type). Export both so the
# documented name keeps working if upstream fixes the derivation.
export OPENAI_COMPATIBLE_API_KEY="$OPENROUTER_API_KEY"

# ADR-0034: THEME_MODE is the single light/dark derivation; aichat only has a
# light-theme boolean. Both branches export — an inherited stale
# AICHAT_LIGHT_THEME must not survive a dark THEME_MODE.
if [[ ${THEME_MODE:-dark} == light ]]; then
  export AICHAT_LIGHT_THEME=true
else
  export AICHAT_LIGHT_THEME=false
fi

exec aichat
