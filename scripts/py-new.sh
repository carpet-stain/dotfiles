#!/usr/bin/env bash
# Bootstraps a new Python project: the git-flow governance base (#136) with the
# Python overlay (#129, #130) layered on top. Applies both copier templates in
# order — git-flow first (its files are the base), then python (whose colliding
# files superset the base's: ci.yml, lefthook.yml, justfile, .gitignore,
# README). `--trust` is required, not optional: the post-gen tasks (uv python
# pin, uv sync, git init, lefthook install) are what makes the result
# deployment-ready rather than a half-wired skeleton, and copier silently skips
# all of them without it — no error, just a project missing its lock file and
# git hooks.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: py-new <path>" >&2
  exit 1
fi

script_dir=$(cd "$(dirname "$(realpath "$0")")" && pwd)
dotfiles_dir=$(dirname "$script_dir")
dest="$1"

# Base governance first, then the Python overlay on top. --overwrite on the
# overlay so its superset files replace the base's colliding ones without
# prompting; the two keep separate answers files
# (.copier-answers.git-flow.yml / .copier-answers.yml), so `copier update`
# tracks each independently.
uvx copier copy --trust "$dotfiles_dir/git-flow" "$dest"
uvx copier copy --trust --overwrite "$dotfiles_dir/python" "$dest"
