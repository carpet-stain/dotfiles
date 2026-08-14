#!/usr/bin/env bash
# Enforces two invariants for .envrc.local.example (the tracked template for
# the gitignored .envrc.local):
#   1. Every export line's value is empty. This is what actually guarantees
#      no real credential can land here, rather than pattern-matching
#      against what a "real-looking" secret happens to look like today.
#   2. It matches .envrc.local structurally (comments, variable names) once
#      values are stripped, so the template can't silently drift from what
#      is actually needed.
set -uo pipefail

example_file=".envrc.local.example"
real_file=".envrc.local"

# [A-Z0-9_], not [A-Z_]: a digit in a var name (R2_...) must not exempt its value
# from stripping (it'd leak via stderr). Keeps `export VAR=` so drift still shows.
strip_values() { sed -E 's/^(export [A-Z0-9_]+=).*/\1/' "$1"; }

if grep -E '^export [A-Z0-9_]+=.+' "$example_file" >/dev/null; then
  echo "error: $example_file has a non-empty export value — replace it with 'export VAR=' (empty)" >&2
  exit 1
fi

# Nothing to compare the template's shape against if .envrc.local doesn't
# exist locally (e.g. CI, or not set up yet on this machine).
[[ -f "$real_file" ]] || exit 0

if ! diff_output="$(diff -u <(strip_values "$real_file") <(strip_values "$example_file"))"; then
  echo "error: $example_file has drifted from $real_file (beyond credential values):" >&2
  echo "$diff_output" >&2
  exit 1
fi
