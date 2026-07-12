#!/usr/bin/env bash
# Backs the `squash` alias in git/config. Rebases onto origin/main *before*
# collapsing to one commit — `git reset --soft origin/main` against a
# moved origin/main stages reverts of whatever landed on main since the
# branch was cut (the reset diffs your old tree against the new target,
# not just your own commits). Rebasing first means the branch already
# sits on origin/main, so the reset only ever collapses the branch's own
# commits, regardless of how stale or fresh the local origin/main ref was
# going in.
set -euo pipefail

git fetch origin main

ahead=$(git rev-list --count origin/main..HEAD)
if [[ "$ahead" -lt 1 ]]; then
  echo "no commits ahead of origin/main to squash" >&2
  exit 1
fi

if ! git rebase origin/main; then
  echo "rebase onto origin/main hit a conflict — resolve it, run: git rebase --continue, then re-run: git squash" >&2
  exit 1
fi

git reset --soft origin/main
git commit
