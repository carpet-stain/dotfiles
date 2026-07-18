#!/usr/bin/env bash
# Backs the `memory-pr` alias in git/config. The only sanctioned way
# backlog-manager's file-based memory reaches git history: branch off
# origin/main, stage strictly .claude/agent-memory/backlog-manager/**,
# commit, push, and open a *draft* PR. Never finalizes or merges — a human
# reviews and lands it by hand, the same checkpoint ADR-0009 protected
# before this script existed (see the ADR amending it for why that's
# convention, not platform enforcement; #333).
set -euo pipefail

MEMORY_DIR=".claude/agent-memory/backlog-manager"

if [[ ! -d "$MEMORY_DIR" ]]; then
  echo "no $MEMORY_DIR here — nothing to sync" >&2
  exit 0
fi

if [[ -z "$(git status --porcelain=v1 -- "$MEMORY_DIR")" ]]; then
  echo "no changes under $MEMORY_DIR to sync" >&2
  exit 0
fi

git fetch origin main
branch="chore/sync-backlog-memory-$(date +%Y%m%d%H%M%S)"
git switch -c "$branch" origin/main

git add -- "$MEMORY_DIR"

# Re-verify the index after staging rather than trust the pathspec alone —
# this is the mechanical guard against a quoting/glob bug in the line
# above, not a defense against unrelated dirty files elsewhere (those never
# entered the index; the pathspec already excludes them).
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

git commit -m "chore(claude): sync backlog-manager memory"
git push -u origin "$branch"

pr_body="## Summary

Backlog-manager memory sync for \`$MEMORY_DIR\`, opened by \`git memory-pr\`.
This never auto-merges — a human reviews and lands it, same checkpoint as
any other change here (ADR-0009, amended for this capability).

## Before merging

- Regression / staleness / duplication: run the \`audit-memory\` skill
  against this diff. It's read-only, no secret-scanning capability.
- Secrets: no automated coverage at all. This human read is the only check
  for a leaked credential or token in memory content — don't skip it.

## Scope

Every changed path is under \`$MEMORY_DIR\` — enforced by this script's
staging guard, not asserted."

gh pr create --draft \
  --title "chore(claude): sync backlog-manager memory" \
  --body "$pr_body"

echo "draft PR opened — review and merge by hand; this script never finalizes or merges." >&2
