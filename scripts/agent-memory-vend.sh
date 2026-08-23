#!/usr/bin/env bash
# agent-memory-vend <role> -- <cmd...> — run one command with the current
# agent-memory bearer set for that process only (#671). Fetches
# /runtime/agent-memory/<role>/bearer-tokens from SSM (agent-memory-server's
# own terraform/ssm.tf, ADR-0046) with the same infra-local-read Keychain
# credential agent-gh/aws-vended-token use, and execs the command with
# AGENT_MEMORY_BEARER set — never exported into the ambient shell (.envrc),
# unlike the routine GH_TOKEN: this credential grants full read+write of the
# role's entire private memory store, so it lives only in the wrapped
# process and dies with it (ADR-0046's operational privacy mitigation).
#
# The SSM value is a JSON array (`bearer-tokens`, plural) — during a
# rotation overlap (agent-memory-server#32, unbuilt) it holds two
# concurrently-valid tokens, both accepted by the server's set-membership
# check, so picking the first element is always correct; there is no
# "current vs. stale" ordering to get right. Never cached: every invocation
# re-reads SSM, so a caller that re-vends after a 401 always gets a live
# token — the retry loop itself belongs to whatever speaks the MCP-over-HTTP
# session (dotfiles#634's client wiring), not this script.
set -euo pipefail

usage() {
  echo "usage: agent-memory-vend <role> -- <cmd> [args...]" >&2
  exit 2
}

role=${1:-}
case $role in
  # Only backlog-manager has a store today — see ADR-0046's roster table.
  backlog-manager) ;;
  *) usage ;;
esac
[[ ${2:-} == -- ]] || usage
shift 2
(($#)) || usage

item=infra-aws-local-read
if ! secret=$(security find-generic-password -s "$item" -w 2>/dev/null); then
  echo "agent-memory-vend: Keychain item '$item' missing or unreadable — see docs/credentials.md for the one-time setup" >&2
  exit 1
fi
key_id=$(security find-generic-password -s "$item" 2>/dev/null |
  sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
if [[ -z $key_id ]]; then
  echo "agent-memory-vend: Keychain item '$item' has no acct attribute (should hold the access key id)" >&2
  exit 1
fi

# AWS credentials live only inside the fetch subshell, never the wrapped command.
bearer=$(
  export AWS_ACCESS_KEY_ID=$key_id AWS_SECRET_ACCESS_KEY=$secret
  export AWS_REGION=us-east-1
  unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null || true
  aws ssm get-parameter --name "/runtime/agent-memory/$role/bearer-tokens" \
    --with-decryption --query Parameter.Value --output text |
    jq -er '.[0] // error("bearer-tokens array is empty")'
)
if [[ -z $bearer ]]; then
  echo "agent-memory-vend: /runtime/agent-memory/$role/bearer-tokens came back empty — agent-memory-server's terraform/ssm.tf provisions it, confirm apply has run" >&2
  exit 1
fi

exec env AGENT_MEMORY_BEARER="$bearer" "$@"
