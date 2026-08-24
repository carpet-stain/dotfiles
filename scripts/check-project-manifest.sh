#!/usr/bin/env bash
# Schema validator for project-manifest.yaml (ADR-0052): structural shape only
# — parses, every anchor is `repo#number`, no duplicate anchors, no anchor
# with an empty dedicated_repos list. Whether a target repo still exists or
# is still actually dedicated is a runtime/judgment call for whatever reads
# the manifest (dotfiles#669's sync, the grooming sweep) — out of scope here,
# matching #669's fail-closed posture of reporting and skipping rather than
# erroring the whole run.
set -uo pipefail

manifest="project-manifest.yaml"
[[ -f "$manifest" ]] || exit 0

anchor_line_re='^  - anchor: (.*)$'
anchor_shape_re='^[a-z0-9_-]+#[0-9]+$'
repo_re='^      - ([a-z0-9_-]+)$'

declare -A seen_anchors
current_anchor=""
pending_repo_count=0
errors=0

flush() {
  if [[ -n "$current_anchor" && "$pending_repo_count" -eq 0 ]]; then
    echo "error: $manifest anchor '$current_anchor' has no dedicated_repos entries" >&2
    errors=$((errors + 1))
  fi
}

while IFS= read -r line; do
  if [[ "$line" =~ $anchor_line_re ]]; then
    flush
    current_anchor="${BASH_REMATCH[1]}"
    pending_repo_count=0
    if [[ ! "$current_anchor" =~ $anchor_shape_re ]]; then
      echo "error: $manifest anchor '$current_anchor' doesn't match the repo#number shape" >&2
      errors=$((errors + 1))
    elif [[ -n "${seen_anchors[$current_anchor]:-}" ]]; then
      echo "error: $manifest has a duplicate anchor '$current_anchor'" >&2
      errors=$((errors + 1))
    fi
    seen_anchors[$current_anchor]=1
  elif [[ "$line" =~ ^\ \ \ \ dedicated_repos:$ ]]; then
    continue
  elif [[ "$line" =~ $repo_re ]]; then
    pending_repo_count=$((pending_repo_count + 1))
  fi
done <"$manifest"
flush

if [[ "$errors" -gt 0 ]]; then
  exit 1
fi
