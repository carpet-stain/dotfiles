#!/usr/bin/env bash
# Backs the `pr` alias in git/config. Asserts the branch is squashed to
# exactly one commit ahead of origin/main before opening the PR — the same
# precondition AGENTS.md's Git workflow documents for `git pr`. PR-to-commit
# association (and the changelog link it produces) is resolved later via
# git-cliff's GitHub remote lookup, not by amending the commit here.
set -euo pipefail

ahead=$(git rev-list --count origin/main..HEAD)
if [[ "$ahead" != 1 ]]; then
  echo "squash to 1 commit first (branch has $ahead vs origin/main): git reset --soft origin/main && git commit" >&2
  exit 1
fi

gh pr create "$@"
