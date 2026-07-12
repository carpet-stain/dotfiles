#!/usr/bin/env bash
# Backs the `new` alias in git/config. Fetches origin/main fresh, then
# branches off it — makes starting from a stale base structurally
# impossible, no separate fetch/switch reasoning needed.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: git new <branch-name>" >&2
  exit 1
fi

git fetch origin main
git switch -c "$1" origin/main
