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
# crown-jewel items. Residency stays Keychain, not SSM (#627, decided against
# infra#170's revisit trigger): measured SSM's `get-parameter` at ~0.33s vs
# Keychain's near-instant local read — perceptible added latency on this
# pane's cold-launch path, which is meant to feel instant. The key now has
# two copies (Keychain here, SSM for the CI reviewer, infra#220/dotfiles#626)
# — rotate both; see docs/credentials.md.
set -euo pipefail

# The pane runs close_on_exit (config.kdl), so warn and exit 0 after a
# keypress rather than leaving a held error pane.
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

# aichat 0.30 reads only OPENAI_COMPATIBLE_API_KEY (env name derives from client
# type — verified vs api.openrouter.ai). Both exported in case upstream fixes it.
export OPENAI_COMPATIBLE_API_KEY="$OPENROUTER_API_KEY"

# Both branches export: a stale inherited AICHAT_LIGHT_THEME must not survive
# a dark THEME_MODE. See ADR-0034.
if [[ ${THEME_MODE:-dark} == light ]]; then
  export AICHAT_LIGHT_THEME=true
else
  export AICHAT_LIGHT_THEME=false
fi

exec aichat
