#!/usr/bin/env bash
# Backs the `pr` alias in git/config. Two explicit modes — never inferred
# from ambient repo state, so intent and actual behavior can't silently
# diverge:
#   git pr --draft   open a draft PR as soon as a first commit exists.
#   git pr           finalize an already-open draft via `gh pr ready`.
# A draft must exist before `git pr` (no flag) can finalize it — there's no
# direct-to-ready path, even for already-verified work: git.md's "Working
# iteratively when you can't self-verify" section is explicit that the
# draft step never gets skipped. Each path asserts its own precondition and
# fails with a specific message.
set -euo pipefail

is_draft=false
for arg in "$@"; do
  [[ "$arg" == "--draft" ]] && is_draft=true
done

# --web (or an aborted create) may leave no PR to look up yet; that's fine,
# absence here just means "no PR for this branch", the same as if one was
# never opened.
existing_pr=$(gh pr view --json number -q .number 2>/dev/null) || existing_pr=""

if $is_draft; then
  if [[ -n "$existing_pr" ]]; then
    echo "PR #$existing_pr already exists for this branch — did you mean to finalize? run: git pr" >&2
    exit 1
  fi
  ahead=$(git rev-list --count origin/main..HEAD)
  if [[ "$ahead" -lt 1 ]]; then
    echo "need at least 1 commit ahead of origin/main to open a draft PR" >&2
    exit 1
  fi
  gh pr create "$@"
  exit 0
fi

if [[ -z "$existing_pr" ]]; then
  echo "no draft PR for this branch — run: git pr --draft first" >&2
  exit 1
fi

# Finalize: a PR already exists for this branch. Fetch + rebase onto
# origin/main here (not just at `git new` start) — finalize is where CI
# actually reads the base, so this is the forcing function that keeps a
# stale-started or since-moved branch from landing a stale-base PR (#172).
git fetch origin main

ahead=$(git rev-list --count origin/main..HEAD)
if [[ "$ahead" != 1 ]]; then
  echo "squash to 1 commit first (branch has $ahead vs origin/main): git reset --soft origin/main && git commit" >&2
  exit 1
fi

if ! git rebase origin/main; then
  echo "rebase onto origin/main hit a conflict — resolve it, run: git rebase --continue, then re-run: git pr" >&2
  exit 1
fi

git push --force-with-lease
gh pr ready
