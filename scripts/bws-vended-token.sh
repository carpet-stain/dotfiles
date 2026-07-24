#!/usr/bin/env bash
# Fetch the vended GitHub token from Bitwarden's vended-tokens Project and
# print it to stdout, or fail loud (stderr + nonzero) if it's stale or missing.
# The token rotates (~1h life, re-vended every 20 min by carpet-stain/infra's
# vend-token.yml), so it's fetched fresh on every call, never cached — see
# infra's docs/CONSUMING-SECRETS.md and dotfiles#377. Consumed by .envrc;
# reusable by any repo that reads the vended token.
#
#   BWS_ACCESS_TOKEN  the Local machine-account token (from .zshenv/Keychain)
#   $1                the vended secret's UUID (BWS_VENDED_SECRET_ID; non-secret)
set -euo pipefail

secret_id=${1:?usage: bws-vended-token <secret-uuid>}
: "${BWS_ACCESS_TOKEN:?BWS_ACCESS_TOKEN not set — Keychain not loaded (see AGENTS.md Credentials)}"

# `bws secret get` returns {key,value,...}; .value is the {token,expires_at}
# JSON string. `--color no` is required: bws emits ANSI-colored JSON even when
# piped to a non-TTY (its `auto` default still colors and NO_COLOR is ignored),
# which isn't parseable. The extract + expiry check run entirely in jq (already
# a hard dependency) so there's no dependence on GNU-vs-BSD `date` flag
# differences — fromdateiso8601 and now are portable. jq -e turns a jq error()
# or a missing/null field into a nonzero exit, which set -e surfaces as a loud
# failure rather than a printed empty or expired token.
bws --color no secret get "$secret_id" --output json | jq -er '
  .value
  | fromjson
  | if (.expires_at | fromdateiso8601) > now then .token
    else error("vended token expired at \(.expires_at) — infra vend-token.yml may have stalled; check Bitwarden")
    end
'
