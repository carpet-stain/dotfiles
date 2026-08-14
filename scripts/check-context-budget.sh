#!/usr/bin/env bash
# Advisory nudge, never a hard failure (ADR-0031's pattern): token-counts the
# agent context that's actually always injected every turn — AGENTS.md and
# the claude/rules files with no native `paths:` frontmatter gate. go.md/python.md/terraform.md are excluded: their
# `paths:` frontmatter means Claude Code itself skips loading them in a repo
# with no matching files (claude/README.md's loading table), so they aren't
# part of the permanent tax this counts. Counting is chars/4, a rough token
# estimate, not a real tokenizer (#436) — the trend and delta matter here,
# not precision; don't "fix" this into a dependency.
set -uo pipefail

# No measured ceiling yet; 20k is a round number with headroom over the real
# total as of #436 (~13k) — retune once #431's spike lands actual numbers.
CEILING_TOKENS=20000

has_paths_gate() {
  [[ "$(sed -n '1p' "$1" 2>/dev/null)" == "---" ]] || return 1
  sed -n '2,/^---$/p' "$1" | grep -q '^paths:'
}

is_context_file() {
  case "$1" in
    AGENTS.md) return 0 ;;
    claude/rules/*/*.md)
      [[ -f "$1" ]] && has_paths_gate "$1" && return 1
      return 0
      ;;
    *) return 1 ;;
  esac
}

all_context_files() {
  {
    [[ -f AGENTS.md ]] && echo AGENTS.md
    find claude/rules -name '*.md' 2>/dev/null
  } | while IFS= read -r f; do
    is_context_file "$f" && echo "$f"
  done
}

tokens_of() {
  [[ -f "$1" ]] || {
    echo 0
    return
  }
  local chars
  chars=$(wc -c <"$1" | tr -d ' ')
  echo $(((chars + 3) / 4))
}

tokens_at_head() {
  local chars
  chars=$(git show "HEAD:$1" 2>/dev/null | wc -c | tr -d ' ')
  echo $(((${chars:-0} + 3) / 4))
}

fmt_k() {
  awk -v n="$1" 'BEGIN { printf "%.1fk", n / 1000 }'
}

[[ $# -gt 0 ]] || exit 0

total=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  total=$((total + $(tokens_of "$f")))
done < <(all_context_files)

reported=0
for arg in "$@"; do
  is_context_file "$arg" || continue
  reported=1
  after=$(tokens_of "$arg")
  before=$(tokens_at_head "$arg")
  printf 'context-budget: %s %s tokens (%+d this commit)\n' "$arg" "$(fmt_k "$after")" "$((after - before))"
done

if [[ $reported -eq 1 ]]; then
  printf 'context-budget: always-loaded total %s / %s advisory ceiling\n' "$(fmt_k "$total")" "$(fmt_k "$CEILING_TOKENS")"
fi

exit 0
