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
# Single-checkout assumption: git itself refuses to check the fixed branch
# out in two worktrees at once, and the force-with-lease pushes below are
# race-safe only because each is preceded by its own fresh fetch — the
# lease compares against the remote-tracking ref, so a stale one would
# turn the lease into a rubber stamp.
set -euo pipefail

MEMORY_DIR=".claude/agent-memory/backlog-manager"
FIXED_BRANCH="chore/sync-backlog-memory"
COMMIT_MSG="chore(claude): sync backlog-manager memory"

if [[ ! -d "$MEMORY_DIR" ]]; then
  echo "no $MEMORY_DIR here — nothing to sync" >&2
  exit 0
fi

git fetch --prune origin main

memory_dirty="$(git status --porcelain=v1 -- "$MEMORY_DIR")"

# Stranded-delta check — a prior run that committed but failed to push
# leaves the fixed branch ahead with a clean memory dir. Ordered before the
# early-exit so a naive re-run can't report a success-shaped "nothing to
# sync" over an unpushed delta. (A dirty memory dir subsumes the strand:
# the rebuild below re-commits the whole dir from the working tree.)
if git show-ref --verify --quiet "refs/heads/$FIXED_BRANCH"; then
  if git show-ref --verify --quiet "refs/remotes/origin/$FIXED_BRANCH"; then
    strand_base="refs/remotes/origin/$FIXED_BRANCH"
  else
    strand_base="refs/remotes/origin/main"
  fi
  ahead="$(git rev-list --count "$strand_base..refs/heads/$FIXED_BRANCH")"
  if [[ "$ahead" -gt 0 && -z "$memory_dirty" ]]; then
    {
      echo "stranded delta: local $FIXED_BRANCH is $ahead commit(s) ahead of ${strand_base#refs/remotes/}"
      echo "with a clean memory dir — a prior run committed but never pushed. Resolve by hand:"
      echo "  git push --force-with-lease origin $FIXED_BRANCH    # push the committed delta as-is"
      echo "or rebuild from the working tree and re-run:"
      echo "  git switch $FIXED_BRANCH && git reset --soft origin/main"
    } >&2
    exit 1
  fi
fi

if [[ -z "$memory_dirty" ]]; then
  echo "no changes under $MEMORY_DIR to sync" >&2
  exit 0
fi

# Tracked non-memory changes (staged or unstaged) would be silently
# destroyed by the re-parent restore below — refuse before any ref moves.
# Untracked files never block: nothing here discards them (the 2026-07-24
# incident's casualty was a tracked-modified file, not an untracked one).
if [[ -n "$(git status --porcelain=v1 --untracked-files=no -- . ":(exclude)$MEMORY_DIR")" ]]; then
  git status --short --untracked-files=no -- . ":(exclude)$MEMORY_DIR" >&2
  echo "refusing: tracked changes outside $MEMORY_DIR (above) — commit or restore them first" >&2
  exit 1
fi

# Entry contract: proceed only from the fixed branch (the state this script
# itself leaves behind) or a checkout whose non-memory tree already equals
# fresh origin/main. A feature-branch HEAD is refused cleanly here, before
# any ref moves — never surprise-flipped onto the sync branch.
current_branch="$(git symbolic-ref --quiet --short HEAD || true)"
if [[ "$current_branch" != "$FIXED_BRANCH" ]] &&
  ! git diff --quiet origin/main -- . ":(exclude)$MEMORY_DIR"; then
  echo "refusing: HEAD diverges from origin/main outside $MEMORY_DIR —" \
    "run from the fixed branch ($FIXED_BRANCH) or an up-to-date main checkout" >&2
  exit 1
fi

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

# Rebuild <branch> as origin/main + the working tree's memory dir, then
# commit. switch -C with implicit HEAD start-point: zero tree change (the
# dirty memory dir carries over), no other ref touched. reset --soft moves
# only the branch ref. The restore re-parents the non-memory index+worktree
# onto fresh origin/main; it depends on restore's default no-overlay mode —
# adds, modifies, and deletes all reconcile exactly; never add --overlay.
# Safe because the dirty guard above proved no tracked non-memory changes
# exist, and committed divergence lives on refs this never touches.
rebuild_and_commit() {
  local branch="$1"
  git switch -C "$branch"
  git reset --soft origin/main
  git restore --source=origin/main --staged --worktree -- . ":(exclude)$MEMORY_DIR"

  git add -- "$MEMORY_DIR"

  # Re-verify the index after staging rather than trust the pathspec alone —
  # a pure backstop against a quoting/glob bug in the line above; it never
  # fires on a healthy path (the restore already reset everything else).
  while IFS= read -r -d '' path; do
    case "$path" in
      "$MEMORY_DIR"/*) ;;
      *)
        git restore --staged -- "$path"
        echo "aborting: staged path outside $MEMORY_DIR: $path" >&2
        exit 1
        ;;
    esac
  done < <(git diff --cached --name-only -z)

  git commit -m "$COMMIT_MSG"
}

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
staging guard, not asserted."

case "$pr_state" in
  false)
    # Rolling PR exists but was flipped ready-for-review: it's the human's
    # turn — hands off the fixed branch entirely. Divert this sync to a
    # fresh timestamped branch and a new draft PR.
    fallback_branch="$FIXED_BRANCH-$(date +%Y%m%d%H%M%S)"
    echo "rolling PR is ready-for-review (human's turn) — diverting to $fallback_branch" >&2
    rebuild_and_commit "$fallback_branch"
    git push --force-with-lease="$fallback_branch": origin "$fallback_branch"
    gh pr create --draft --title "$COMMIT_MSG" --body "$pr_body

> Opened on a timestamped branch because the rolling PR was already
> ready-for-review. After both land, delete this branch's local copy;
> \`git memory-pr\` returns to the fixed branch on its own."
    ;;
  true)
    # Update path: refresh the lease baseline first — force-with-lease
    # without it would compare against a stale remote-tracking ref.
    rebuild_and_commit "$FIXED_BRANCH"
    git fetch origin "$FIXED_BRANCH"
    if ! git push --force-with-lease origin "$FIXED_BRANCH"; then
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
    # Create path: empty-expectation lease — the remote ref must not
    # exist. A lingering branch from a closed-unmerged PR fails loud here
    # instead of being silently overwritten.
    rebuild_and_commit "$FIXED_BRANCH"
    if ! git push --force-with-lease="$FIXED_BRANCH": origin "$FIXED_BRANCH"; then
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
    gh pr create --draft --title "$COMMIT_MSG" --body "$pr_body"
    echo "rolling draft PR opened — review and merge by hand; this script never finalizes or merges." >&2
    ;;
  *)
    echo "unexpected gh pr list output: $pr_state" >&2
    exit 1
    ;;
esac
