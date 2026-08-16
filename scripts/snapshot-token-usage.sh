#!/usr/bin/env bash
# Weekly durable token-usage snapshot (#518, spike #431's durability layer):
# transcripts prune at 30 days (cleanupPeriodDays), so this captures #516's
# ccusage coarse numbers and #517's attribution rollup into
# $XDG_STATE_HOME — outside that pruned window — before they're gone. Timer
# only, no daemon: see macos/com.carpet-stain.dotfiles.token-usage-snapshot.plist.
set -euo pipefail

# Resolve through the symlink, not a hardcoded path — $DOTFILES_DIR can be a
# worktree at deploy time (see deploy.zsh's brew.env symlink note).
repo_root=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/token-usage"
mkdir -p "$state_dir"
stamp=$(date +%Y-%m-%d)
cd "$repo_root"

failures=0

tmp=$(mktemp)
if just usage weekly --json >"$tmp"; then
  mv "$tmp" "$state_dir/ccusage-$stamp.json"
else
  rm -f "$tmp"
  echo "snapshot-token-usage: ccusage capture failed" >&2
  failures=$((failures + 1))
fi

tmp=$(mktemp)
if just token-attribution >"$tmp"; then
  mv "$tmp" "$state_dir/attribution-$stamp.json"
else
  rm -f "$tmp"
  echo "snapshot-token-usage: token-attribution capture failed" >&2
  failures=$((failures + 1))
fi

exit "$failures"
