#!/usr/bin/env bash
# Per-spike/issue token accounting (#476, spike #431's application layer):
# posts #517's per-issue rollup as a closing comment, the real-spend number
# backlog-manager's grooming calibrates effort estimates against.
set -euo pipefail

repo_root=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
issue=${1:?usage: record-token-cost.sh <issue-number>}

cd "$repo_root"
report=$(just token-attribution)
entry=$(jq --argjson n "$issue" '.by_issue[] | select(.issue == $n)' <<<"$report")

# Non-issue-N/fix-N branches still get tokens recorded, keyed by raw branch
# name instead — fall back to that before giving up. See #650.
if [[ -z $entry ]]; then
  current_branch=$(git branch --show-current)
  entry=$(jq --arg b "$current_branch" '.by_issue[] | select(.branch == $b)' <<<"$report")
fi

if [[ -z $entry ]]; then
  echo "record-token-cost: no local transcripts attribute output tokens to issue #$issue (branch '${current_branch:-unknown}' never ran here)" >&2
  exit 1
fi

output_tokens=$(jq -r '.output_tokens' <<<"$entry")
cache_read_tokens=$(jq -r '.cache_read_tokens' <<<"$entry")

comment="Token cost (from this machine's local transcripts, #517's per-issue rollup): **${output_tokens} output tokens**, **${cache_read_tokens} cache-read tokens** across local sessions attributed to issue #${issue}.

Only reflects sessions run on this machine — a stopgap until #517's rollup is itself durable across machines. See #431 for the accounting model."

gh issue comment "$issue" --body "$comment"
