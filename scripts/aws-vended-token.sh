#!/usr/bin/env bash
# Fetch the vended GitHub token from SSM's /runtime/vended-token and print it
# to stdout, or fail loud (stderr + nonzero) if it's stale or missing. The
# token rotates (~1h life, re-vended every 5 min by carpet-stain/infra's
# vend-token.yml), so it's fetched fresh on every call, never cached — see
# infra's ADR-0010 and dotfiles#377 (the Bitwarden-era design this preserves;
# the store swap is infra#125). Consumed by .envrc; reusable by any repo that
# reads the vended token.
#
# Credentials: the infra-local-read IAM user's access key, from the macOS
# login Keychain item `infra-aws-local-read` (acct attribute = key id,
# password = secret key — same shape as infra's `infra-aws-bootstrap` item).
# Added with -A (silent reads): the key is routine, runtime-tier-only — by
# construction it can't decrypt anything under /infra/* (infra's iam/main.tf).
# Exported for this process only, never ambiently — AWS_* env names stay free
# for other tools (infra's local tofu uses them for R2).
set -euo pipefail

item=infra-aws-local-read
if ! secret=$(security find-generic-password -s "$item" -w 2>/dev/null); then
  echo "aws-vended-token: Keychain item '$item' missing or unreadable — see AGENTS.md Credentials for the one-time setup" >&2
  exit 1
fi
key_id=$(security find-generic-password -s "$item" 2>/dev/null |
  sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
if [[ -z $key_id ]]; then
  echo "aws-vended-token: Keychain item '$item' has no acct attribute (should hold the access key id)" >&2
  exit 1
fi

export AWS_ACCESS_KEY_ID=$key_id AWS_SECRET_ACCESS_KEY=$secret
# Parameters are regional; us-east-1 is pinned in infra (ADR-0010). Unset any
# ambient profile/session so exactly this credential is used.
export AWS_REGION=us-east-1
unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null || true

# jq -e, not jq: a missing field or an expired token must exit nonzero, never
# print an empty or stale token — fail-closed, see ADR-0041.
aws ssm get-parameter --name /runtime/vended-token --with-decryption \
  --query Parameter.Value --output text | jq -er '
  if (.expires_at | fromdateiso8601) > now then .token
  else error("vended token expired at \(.expires_at) — infra vend-token.yml may have stalled; check its runs")
  end
'
