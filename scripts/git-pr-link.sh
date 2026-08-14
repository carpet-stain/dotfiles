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
# The draft path also defaults --title to the HEAD commit subject: `gh pr
# create` only prompts for a title in a tty, so a non-interactive shell
# (every agent session) errors demanding one otherwise (#452). The title is
# mechanically irrelevant in this branch model — rebase-merge lands the
# squashed commit verbatim — so this default is safe; an explicit
# --title/-t still overrides.
set -euo pipefail

is_draft=false
for arg in "$@"; do
  [[ "$arg" == "--draft" ]] && is_draft=true
done

# --web or an aborted create may leave no PR to look up; absence just means
# "no PR for this branch".
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

  # `gh pr create` only seeds the PR template in its interactive editor flow
  # (#307), so default the body here; body-supplying flags still override.
  has_body=false
  has_title=false
  for arg in "$@"; do
    case "$arg" in
      -b | --body | -F | --body-file | -f | --fill | --fill-first | --fill-verbose | -e | --editor | -T | --template | -w | --web) has_body=true ;;
    esac
    case "$arg" in
      -t | --title | -f | --fill | --fill-first | --fill-verbose | -e | --editor | -w | --web) has_title=true ;;
    esac
  done
  title_args=()
  if ! $has_title; then
    title_args=(--title "$(git log -1 --pretty=%s)")
  fi
  template="$(git rev-parse --show-toplevel)/.github/pull_request_template.md"
  if ! $has_body && [[ -f "$template" ]]; then
    gh pr create "$@" "${title_args[@]}" --body-file "$template"
  else
    gh pr create "$@" "${title_args[@]}"
  fi
  exit 0
fi

if [[ -z "$existing_pr" ]]; then
  echo "no draft PR for this branch — run: git pr --draft first" >&2
  exit 1
fi

# Rebase at finalize, not just at `git new`: finalize is where CI reads the
# base, so this is what keeps a stale-base PR from landing (#172).
git fetch origin main

ahead=$(git rev-list --count origin/main..HEAD)
if [[ "$ahead" != 1 ]]; then
  echo "squash to 1 commit first (branch has $ahead vs origin/main): git squash" >&2
  exit 1
fi

if ! git rebase origin/main; then
  echo "rebase onto origin/main hit a conflict — resolve it, run: git rebase --continue, then re-run: git pr" >&2
  exit 1
fi

# Ready before push: both events share a head SHA and pr-guards.yml's
# draft-gated jobs evaluate once — push-first leaves them skipped (ADR-0015).
gh pr ready
git push --force-with-lease
