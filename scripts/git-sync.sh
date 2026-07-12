#!/usr/bin/env bash
# Backs the `sync` alias in git/config. Fast-forwards local main to match
# origin/main — safe and loud under merge.ff=only, which refuses anything
# that isn't a clean fast-forward.
set -euo pipefail

git fetch --prune origin
git switch main
git merge --ff-only origin/main
