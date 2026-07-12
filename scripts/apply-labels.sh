#!/usr/bin/env bash
# Idempotent label taxonomy bootstrap: upserts every label in labels.json
# onto the repo in the current working directory. Run from inside the
# target repo's checkout, same convention as bootstrap-branch-protection.sh.
#
# Upsert only — never prunes. A repo's own labels beyond this taxonomy
# (e.g. this repo's "theme: *" set) are left alone.
#
# `gh label create` needs the Issues permission, which the routine scoped
# GH_TOKEN (Contents/Pull requests/Actions, see .envrc.local.example) doesn't
# carry either. This is a one-time-per-repo bootstrap action, not routine
# day-to-day work, so it runs under the same elevated fallback session as
# bootstrap-branch-protection.sh rather than widening the routine token's
# scope for a single script:
#   env -u GH_TOKEN scripts/apply-labels.sh
#
# Future direction: once repos-as-code work lands (Terraform, github
# provider — not yet started), replace this with a `github_issue_label`
# resource, `for_each`'d over the same list, applied identically across
# bootstrapped repos. Keep this script only as the interim mechanism until
# that lands.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MANIFEST="${SCRIPT_DIR}/labels.json"

# Process substitution, not a `jq ... | while read` pipe: the while loop
# must run in the current shell, not a subshell, so `exit 1` below actually
# aborts the script instead of just the pipeline stage.
while read -r label; do
  name=$(jq -r '.name' <<<"$label")
  color=$(jq -r '.color' <<<"$label")
  description=$(jq -r '.description' <<<"$label")
  if error=$(gh label create "$name" --color "$color" --description "$description" --force 2>&1); then
    echo "ok: $name"
  else
    echo "$error" >&2
    echo "error: failed to upsert label '$name' — likely missing Issues scope." >&2
    echo "retry with: env -u GH_TOKEN $0" >&2
    exit 1
  fi
done < <(jq -c '.[]' "$MANIFEST")

echo "done: labels applied from ${MANIFEST}"
