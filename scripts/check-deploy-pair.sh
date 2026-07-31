#!/usr/bin/env bash
# Advisory pre-push nudge (#493): macos/deploy.zsh and linux/deploy.sh are
# parallel bootstrap scripts with no shared lib (AGENTS.md: "when one
# changes, check the other") — a one-sided edit silently drifts the two
# targets. Whole-branch (three-dot origin/main...HEAD, adr-guard.yml:57's
# precedent), not per-commit: this repo's split-WIP-then-squash flow means a
# single commit touching only one side is fine as long as the branch as a
# whole covers both. Never blocks — a one-sided edit is often legitimate
# (a macOS-only Brewfile tweak), so this only surfaces the outlier.
set -uo pipefail

if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  echo "check-deploy-pair: skipped: no origin/main ref"
  exit 0
fi

changed="$(git diff --name-only origin/main...HEAD)"

macos_touched=false
linux_touched=false
grep -qx 'macos/deploy.zsh' <<<"$changed" && macos_touched=true
grep -qx 'linux/deploy.sh' <<<"$changed" && linux_touched=true

if [[ "$macos_touched" == true && "$linux_touched" == false ]]; then
  echo "check-deploy-pair: macos/deploy.zsh changed but linux/deploy.sh didn't — check the other (AGENTS.md)"
elif [[ "$macos_touched" == false && "$linux_touched" == true ]]; then
  echo "check-deploy-pair: linux/deploy.sh changed but macos/deploy.zsh didn't — check the other (AGENTS.md)"
fi

exit 0
