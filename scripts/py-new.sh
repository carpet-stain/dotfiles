#!/usr/bin/env bash
# Bootstraps a new Python project from this repo's copier template (#129,
# #130). `--trust` is required, not optional: the template's post-gen tasks
# (uv python pin, uv sync, git init, lefthook install) are what makes the
# result deployment-ready rather than a half-wired skeleton, and copier
# silently skips all of them without it -- no error, just a project missing
# its lock file and git hooks.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: py-new <path>" >&2
  exit 1
fi

script_dir=$(cd "$(dirname "$(realpath "$0")")" && pwd)
dotfiles_dir=$(dirname "$script_dir")

uvx copier copy --trust "$dotfiles_dir/python" "$1"
