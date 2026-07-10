#!/usr/bin/env bash
# pre-push hook (wired via .pre-commit-config.yaml): sync-dev.yml rewrites
# dev's history after every merge, which routinely makes a plain `git push`
# get rejected. This catches that before the push goes out and rebases
# automatically, instead of waiting for the rejection and doing it by hand.
#
# Can't finish the *same* push after rebasing mid-flight — by the time this
# hook runs, git has already fixed which local SHA it intends to push, so
# rewriting history here doesn't retroactively change that. Exits nonzero
# after a successful rebase so the push is blocked with a clear next step,
# rather than silently completing a push whose target has moved.
set -uo pipefail

remote_name="$PRE_COMMIT_REMOTE_NAME"
local_ref="$PRE_COMMIT_LOCAL_BRANCH"
remote_ref="$PRE_COMMIT_REMOTE_BRANCH"

# Only applies to branch pushes — tags etc. have nothing to "rebase".
case "$local_ref" in refs/heads/*) ;; *) exit 0 ;; esac
case "$remote_ref" in refs/heads/*) ;; *) exit 0 ;; esac

local_branch="${local_ref#refs/heads/}"
remote_branch="${remote_ref#refs/heads/}"

if ! git fetch --quiet "$remote_name" "$remote_branch" 2>/dev/null; then
  exit 0 # remote branch doesn't exist yet (first push) — nothing to compare against
fi

fresh_remote_sha="$(git rev-parse FETCH_HEAD)"
local_sha="$(git rev-parse "$local_branch")"

if git merge-base --is-ancestor "$fresh_remote_sha" "$local_sha" 2>/dev/null; then
  exit 0 # already up to date / clean fast-forward — let the push proceed
fi

echo "warning: $remote_name/$remote_branch moved — rebasing $local_branch onto it" >&2
if git rebase "$fresh_remote_sha" "$local_branch"; then
  echo "rebased $local_branch onto the latest $remote_name/$remote_branch — run 'git push' again" >&2
else
  git rebase --abort
  echo "rebase hit conflicts — resolve manually (git fetch && git rebase $remote_name/$remote_branch), then push again" >&2
fi
exit 1
