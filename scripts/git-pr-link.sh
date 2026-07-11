#!/usr/bin/env bash
# Backs the `pr` alias in git/config. Rebase-merge (adopted in #107) lands a
# PR's single commit on main verbatim, unlike the squash-merge it replaced,
# which auto-appended " (#N)" to the commit subject — the exact text
# cliff.toml's commit_preprocessors turns into a changelog PR link. Nothing
# else produces that text anymore, so this does: create the PR, then amend
# the subject to append it before the commit ever lands on main.
set -euo pipefail

ahead=$(git rev-list --count origin/main..HEAD)
if [[ "$ahead" != 1 ]]; then
  echo "squash to 1 commit first (branch has $ahead vs origin/main): git reset --soft origin/main && git commit" >&2
  exit 1
fi

gh pr create "$@"

# --web (or an aborted create) may leave no PR to look up yet; that's fine,
# the alias's job was just to open one.
pr_number=$(gh pr view --json number -q .number 2>/dev/null) || exit 0

subject=$(git log -1 --format=%s)
if [[ "$subject" == *"(#$pr_number)" ]]; then
  exit 0
fi

body=$(git log -1 --format=%b)
if [[ -n "$body" ]]; then
  git commit --amend -m "$subject (#$pr_number)" -m "$body"
else
  git commit --amend -m "$subject (#$pr_number)"
fi
git push --force-with-lease
