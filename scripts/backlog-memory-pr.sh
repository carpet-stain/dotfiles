#!/usr/bin/env bash
# Backs the `memory-pr` alias in git/config. The only sanctioned way
# backlog-manager's file-based memory reaches git history: one fixed branch
# ($FIXED_BRANCH below) carrying one rolling draft PR. Every run rebuilds
# that branch as a single fresh commit on top of fresh origin/main from the
# working tree's memory dir — the working tree is the single source of
# truth; never merge, never amend. The draft PR is the buffer decoupling
# write cadence (each session-end sync) from merge cadence (the human's
# leisure); a quietly-accumulating draft is the design working, not a
# backlog (ADR-0032, amending ADR-0027). Fail loud everywhere: no
# auto-retry, no auto-delete, no fallthrough.
#
# The sync commit is built in a throwaway temp index, never in the primary
# work-tree or its real index: `git read-tree origin/main` seeds a scratch
# index, `git add -A` (redirected to that index via $GIT_INDEX_FILE) layers
# the memory dir's current working-tree content on top, and `commit-tree`
# produces a dangling commit object with no local ref ever created. The
# primary tree, index, and HEAD are untouched by construction — not merely
# by convention — so an unrelated dirty file, a feature-branch HEAD, a
# stale local main, or a dirty submodule pin are all irrelevant; no
# clean-tree or HEAD-divergence guard is needed. A push failure just leaves
# an unreferenced object for git to garbage-collect eventually — nothing
# strands, since nothing local ever pointed at it (ADR-0032 amendment,
# #498).
#
# `--force-with-lease` is the sole concurrency guard now (there is no local
# checkout of the fixed branch to fall back on): every push uses the
# explicit `<ref>:<expected-sha>` form, with the expected sha read from a
# fetch done immediately beforehand, so a stale expectation can't turn the
# lease into a rubber stamp.
set -euo pipefail

MEMORY_DIR=".claude/agent-memory/backlog-manager"
FIXED_BRANCH="chore/sync-backlog-memory"
COMMIT_MSG="chore(claude): sync backlog-manager memory"

cd "$(git rev-parse --show-toplevel)"

if [[ ! -d "$MEMORY_DIR" ]]; then
  echo "no $MEMORY_DIR here — nothing to sync" >&2
  exit 0
fi

git fetch --prune origin main
if git ls-remote --exit-code --heads origin "$FIXED_BRANCH" >/dev/null; then
  git fetch origin "$FIXED_BRANCH"
fi
git fetch --prune origin "refs/heads/$FIXED_BRANCH-*:refs/remotes/origin/$FIXED_BRANCH-*"

# Build the sync commit. mktemp's file starts zero-byte, which read-tree
# treats as a corrupt index — remove it first so git initializes a fresh
# one at that path.
tmpidx="$(mktemp)"
trap 'rm -f "$tmpidx"' EXIT
rm -f "$tmpidx"

GIT_INDEX_FILE="$tmpidx" git read-tree origin/main
GIT_INDEX_FILE="$tmpidx" git add -A -- "$MEMORY_DIR"
tree="$(GIT_INDEX_FILE="$tmpidx" git write-tree)"

# Backstop: the pathspec above should make this a no-op diff by
# construction (read-tree seeded everything else straight from
# origin/main); if it isn't, a pathspec/glob bug staged something outside
# the memory dir.
if ! git diff --quiet origin/main "$tree" -- . ":(exclude)$MEMORY_DIR"; then
  echo "aborting: built tree differs from origin/main outside $MEMORY_DIR" >&2
  exit 1
fi

commit="$(git commit-tree "$tree" -p origin/main -m "$COMMIT_MSG")"

# Route on the open PR for the fixed branch. A failed query aborts — it
# must never fall through to "create" and fork a duplicate of a PR it
# merely failed to see. isDraft is read once; a human flipping the PR
# ready between this lookup and the push is accepted as low-risk (it's a
# human-paced action) — the next run routes correctly.
if ! pr_state="$(gh pr list --head "$FIXED_BRANCH" --state open --json isDraft --jq '.[].isDraft')"; then
  echo "gh pr list failed — cannot tell whether the rolling PR exists; fix connectivity/auth and re-run" >&2
  exit 1
fi
if [[ "$(wc -l <<<"$pr_state")" -gt 1 ]]; then
  echo "more than one open PR with head $FIXED_BRANCH — resolve by hand: gh pr list --head $FIXED_BRANCH" >&2
  exit 1
fi

pr_body="## Summary

Rolling backlog-manager memory sync for \`$MEMORY_DIR\`, maintained by
\`git memory-pr\`. Each sync force-pushes one fresh commit rebuilt on
\`origin/main\` — the working tree is the source of truth. This PR never
auto-merges: a human reviews and lands it (ADR-0027, amended by ADR-0032).
Sitting unmerged for a while is the design working, not a backlog.

## Before merging

- Regression / staleness / duplication: run the \`audit-memory\` skill
  against this diff **in a fresh-context subagent** — the auditor is not
  the author (#412). Note the audited commit SHA in a PR comment; a later
  force-push makes that audit stale — re-run against the new head.
- Secrets: gitleaks scans this path automatically (lefthook pre-commit +
  CI's lint job once the PR is flipped ready) — the human read here is the
  judgment layer on top of that floor, not the only coverage.

## Scope

Every changed path is under \`$MEMORY_DIR\` — enforced by the script's
tree-diff backstop, not asserted."

# Nothing-to-sync is checked per routing path, against the baseline that
# path's diff will actually land against — not a single fixed baseline —
# so an idle run diffs clean instead of forking a duplicate PR or
# invalidating a pending audit with a no-op re-push.
case "$pr_state" in
  false)
    # Rolling PR exists but was flipped ready-for-review: it's the human's
    # turn — hands off the fixed branch entirely. Divert this sync to a
    # fresh timestamped branch and a new draft PR. Baseline is the newest
    # existing fork of that branch (if a prior divert already happened),
    # falling back to the fixed branch itself — comparing against
    # origin/$FIXED_BRANCH here would re-fork a duplicate PR on every
    # repeat sync once diverted.
    newest_fork="$(git for-each-ref --sort=-refname --format='%(refname:short)' "refs/remotes/origin/$FIXED_BRANCH-*" | head -1)"
    baseline_ref="${newest_fork:-refs/remotes/origin/$FIXED_BRANCH}"
    if git diff --quiet "$baseline_ref" "$commit" -- "$MEMORY_DIR"; then
      echo "no changes under $MEMORY_DIR since the last diverted sync — nothing to do" >&2
      exit 0
    fi
    fallback_branch="$FIXED_BRANCH-$(date +%Y%m%d%H%M%S)"
    echo "rolling PR is ready-for-review (human's turn) — diverting to $fallback_branch" >&2
    if ! git push --force-with-lease="$fallback_branch": origin "$commit:refs/heads/$fallback_branch"; then
      echo "push refused — $fallback_branch already exists on the remote (clock collision?); re-run" >&2
      exit 1
    fi
    gh pr create --draft --head "$fallback_branch" --title "$COMMIT_MSG" --body "$pr_body

> Opened on a timestamped branch because the rolling PR was already
> ready-for-review. After both land, delete this branch's local copy;
> \`git memory-pr\` returns to the fixed branch on its own."
    ;;
  true)
    if git diff --quiet "refs/remotes/origin/$FIXED_BRANCH" "$commit" -- "$MEMORY_DIR"; then
      echo "no changes under $MEMORY_DIR to sync" >&2
      exit 0
    fi
    # Refresh the lease baseline right before pushing — the top-of-script
    # fetch is fine for routing/nothing-to-sync, but the lease itself needs
    # the freshest possible expected-sha to stay race-safe.
    git fetch origin "$FIXED_BRANCH"
    old_sha="$(git rev-parse "refs/remotes/origin/$FIXED_BRANCH")"
    if ! git push "--force-with-lease=$FIXED_BRANCH:$old_sha" origin "$commit:refs/heads/$FIXED_BRANCH"; then
      {
        echo "push lease failed — the remote branch moved outside this run. Disambiguate:"
        echo "  gh pr list --head $FIXED_BRANCH --state all"
        echo "then either delete an orphaned remote branch and re-run:"
        echo "  git push origin --delete $FIXED_BRANCH"
        echo "or, if another run raced this one, just re-run to rebuild on the fresh state."
      } >&2
      exit 1
    fi
    echo "rolling draft PR updated in place — review and merge by hand." >&2
    ;;
  "")
    if git diff --quiet origin/main "$commit" -- "$MEMORY_DIR"; then
      echo "no changes under $MEMORY_DIR to sync" >&2
      exit 0
    fi
    # Create path: empty-expectation lease — the remote ref must not
    # exist. A lingering branch from a closed-unmerged PR fails loud here
    # instead of being silently overwritten.
    if ! git push --force-with-lease="$FIXED_BRANCH": origin "$commit:refs/heads/$FIXED_BRANCH"; then
      {
        echo "push refused — a remote $FIXED_BRANCH already exists with no open PR"
        echo "(likely a closed-unmerged PR's leftover). Disambiguate:"
        echo "  gh pr list --head $FIXED_BRANCH --state all"
        echo "then either delete the orphan and re-run:"
        echo "  git push origin --delete $FIXED_BRANCH"
        echo "or reopen the closed PR by hand."
      } >&2
      exit 1
    fi
    # A previously-closed PR on this branch is a known state — create
    # fresh, never reopen.
    gh pr create --draft --head "$FIXED_BRANCH" --title "$COMMIT_MSG" --body "$pr_body"
    echo "rolling draft PR opened — review and merge by hand; this script never finalizes or merges." >&2
    ;;
  *)
    echo "unexpected gh pr list output: $pr_state" >&2
    exit 1
    ;;
esac
