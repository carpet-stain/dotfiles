#!/usr/bin/env bash
# Blocking signpost cap, not a length nudge — see ADR-0044 (supersedes ADR-0031).
# THRESHOLD_LINES is the max allowed, so the comparison is `>`, not `>=`.
set -uo pipefail

THRESHOLD_LINES=2

comment_prefix_for() {
  case "$1" in
    *.lua) echo '--' ;;
    *.mjs | *.cjs | *.js) echo '//' ;;
    *.py | *.tf | *.tfvars) echo '#' ;;
    *.zsh | *.sh | *.bash | *.zshenv | *.zshrc | *.envrc | *.envrc.local.example) echo '#' ;;
    *) echo '' ;;
  esac
}

status=0

for file in "$@"; do
  [[ -f "$file" ]] || continue
  prefix=$(comment_prefix_for "$file")
  [[ -n "$prefix" ]] || continue

  awk -v prefix="$prefix" -v threshold="$THRESHOLD_LINES" -v file="$file" '
    function report() {
      # A block starting at line 1 (or line 2, right after a shebang) is a
      # file-header preamble, not a single-declaration comment — out of scope.
      if (start <= 1) return
      if (start == 2 && header_shebang) return
      if (count > threshold) {
        printf "%s:%d: %d-line comment block on one declaration — cap is %d (tripwire + pointer); relocate the why to its ADR/issue home (design-principles.md)\n", file, start, count, threshold
        found = 1
      }
    }
    NR == 1 && $0 ~ /^#!/ { header_shebang = 1 }
    $0 ~ ("^[ \t]*" prefix "([ \t]|$)") {
      if (count == 0) start = NR
      count++
      next
    }
    { report(); count = 0 }
    END { report(); exit found ? 1 : 0 }
  ' "$file" || status=1
done

exit "$status"
