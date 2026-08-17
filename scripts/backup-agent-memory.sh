#!/usr/bin/env bash
# Interim DR stopgap for the local agent-memory store (dotfiles#542, narrowed
# by #581's hosted-DB pivot to just this): overwrite one well-known key in
# the versioned B2 bucket (infra ADR-0017/0018) so a disk failure doesn't
# erase the only copy. B2 versions a same-name upload instead of destroying
# it, so no timestamped-key scheme is needed. Disposable — replaced once
# #581's hosted store carries its own DR.
#
# Credentials: B2_APPLICATION_KEY_ID/B2_APPLICATION_KEY (the b2 CLI's native
# env vars) come from SSM /runtime/agent-memory-backup-key — a no-delete-
# scoped key (writeFiles + listBuckets, never deleteFiles; infra#200),
# fetched fresh each run via the same infra-aws-local-read Keychain
# credential aws-vended-token.sh uses. No B2 key material at rest on disk.
#
# Healthchecks.io ping is optional here: a missing Keychain item degrades to
# "no liveness alerting yet", not a failure — see docs/credentials.md for
# the one-time setup once a check exists.
set -euo pipefail

bucket=carpet-stain-agent-memory-backups
remote_key=backlog-manager.jsonl
store="${HOME}/.claude/agent-memory-mcp/backlog-manager.jsonl"
ssm_param=/runtime/agent-memory-backup-key
aws_keychain_item=infra-aws-local-read

if [[ ! -f $store ]]; then
  echo "backup-agent-memory: no store at $store yet, nothing to back up" >&2
  exit 0
fi

command -v b2 >/dev/null || {
  echo "backup-agent-memory: b2 not installed — brew install b2-tools (macos/Brewfile.dev)" >&2
  exit 1
}

if ! aws_secret=$(security find-generic-password -s "$aws_keychain_item" -w 2>/dev/null); then
  echo "backup-agent-memory: Keychain item '$aws_keychain_item' missing or unreadable — see AGENTS.md Credentials" >&2
  exit 1
fi
aws_key_id=$(security find-generic-password -s "$aws_keychain_item" 2>/dev/null |
  sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
export AWS_ACCESS_KEY_ID=$aws_key_id AWS_SECRET_ACCESS_KEY=$aws_secret AWS_REGION=us-east-1
unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null || true

b2_creds=$(aws ssm get-parameter --name "$ssm_param" --with-decryption \
  --query Parameter.Value --output text) || {
  echo "backup-agent-memory: failed to fetch $ssm_param from SSM — the infra companion issue may not have landed yet" >&2
  exit 1
}
export B2_APPLICATION_KEY_ID B2_APPLICATION_KEY
B2_APPLICATION_KEY_ID=$(jq -er .key_id <<<"$b2_creds")
B2_APPLICATION_KEY=$(jq -er .application_key <<<"$b2_creds")

ping_url=$(security find-generic-password -s healthchecks-agent-memory-backup -w 2>/dev/null || true)

if b2 file upload "$bucket" "$store" "$remote_key" >/dev/null; then
  [[ -n $ping_url ]] && curl -fsS --retry 3 -o /dev/null "$ping_url"
  exit 0
fi

status=$?
[[ -n $ping_url ]] && curl -fsS --retry 3 -o /dev/null "$ping_url/fail" || true
exit "$status"
