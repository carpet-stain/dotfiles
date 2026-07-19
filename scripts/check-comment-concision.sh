#!/usr/bin/env bash
# Advisory nudge, never a hard failure (#375): flags a comment block that's an
# outlier length for a single declaration, as a prompt to re-read it for
# content already covered elsewhere (design-principles.md's pointer rule) —
# it doesn't try to detect redundancy itself. THRESHOLD_LINES is calibrated
# against this repo's own real blocks, not a guess: the densest legitimate
# single-declaration comment found here is linux/deploy.sh's 15-line
# generate_ghostty_terminfo block, so the threshold sits comfortably above it
# to avoid crying wolf on this repo's normal (dense but non-redundant) style.
set -uo pipefail

THRESHOLD_LINES=20

comment_prefix_for() {
  case "$1" in
    *.lua) echo '--' ;;
    *.zsh | *.sh | *.bash | *.zshenv | *.zshrc | *.envrc | *.envrc.local.example) echo '#' ;;
    *) echo '' ;;
  esac
}

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
      if (count >= threshold) {
        printf "%s:%d: %d-line comment block on one declaration — re-read for content already covered elsewhere (design-principles.md pointer rule)\n", file, start, count
      }
    }
    NR == 1 && $0 ~ /^#!/ { header_shebang = 1 }
    $0 ~ ("^[ \t]*" prefix "([ \t]|$)") {
      if (count == 0) start = NR
      count++
      next
    }
    { report(); count = 0 }
    END { report() }
  ' "$file"
done

exit 0
