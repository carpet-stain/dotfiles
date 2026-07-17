#!/usr/bin/env bash
# Retrofit the git-flow governance templates onto an EXISTING repo, additively
# (#282). `copier copy --overwrite` replaces colliding files and plain copy
# prompts per file, so neither is safe here; instead this generates the
# template output into a temp tree and git-merges it into the target as an
# unrelated history. git's 3-way merge is the additive semantics wanted:
# absent file -> created, existing file -> add/add conflict with both contents
# under markers for the operator to resolve, nothing ever deleted. Greenfield
# repos don't need this — use py-new / `copier copy` there.
#
# Answers are derived from the repo itself (origin URL, default branch, git
# user, pyproject description) and everything else takes template defaults —
# the result is ordinary conflict-resolvable text, so wrong guesses are fixed
# in the same resolution pass, not re-prompted.
#
# usage: scripts/retrofit-governance.sh [--python] [dir]
#   --python  also layer the python overlay (ci test job, ruff/pyright hooks)
#   dir       target repo (default: .)
set -euo pipefail

PYTHON=false
TARGET="."
for arg in "$@"; do
  case "$arg" in
    --python) PYTHON=true ;;
    -*)
      echo "usage: $0 [--python] [dir]" >&2
      exit 1
      ;;
    *) TARGET="$arg" ;;
  esac
done

script_dir=$(cd "$(dirname "$(realpath "$0")")" && pwd)
dotfiles_dir=$(dirname "$script_dir")
cd "$TARGET"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: $TARGET is not a git repository." >&2
  exit 1
}
# Merging into a dirty tree tangles the operator's WIP with the retrofit —
# require a clean slate so the merge (or an abort) is the only change.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree not clean — commit or stash first." >&2
  exit 1
fi

if ! url=$(git remote get-url origin 2>/dev/null); then
  echo "error: no 'origin' remote — the base template needs the GitHub owner/repo." >&2
  exit 1
fi
# Both ssh (git@github.com:o/r.git) and https (https://github.com/o/r) forms.
owner_repo=$(echo "$url" | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')
owner=${owner_repo%%/*}
repo=${owner_repo##*/}
branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
branch=${branch:-main}

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# --skip-tasks: post-gen tasks (git init, lefthook install, uv sync) make a
# live repo work; a merge source doesn't need them, and skipping keeps
# generated artifacts like uv.lock out of the merge. The templates write no
# copier-answers file (ADR-0021), so there's nothing update-related to carry.
uvx copier copy --trust --skip-tasks --defaults \
  -d github_owner="$owner" -d github_repo="$repo" -d protected_branch="$branch" \
  "$dotfiles_dir/git-flow" "$T"

if $PYTHON; then
  desc=""
  [[ -f pyproject.toml ]] && desc=$(sed -n 's/^description = "\(.*\)"/\1/p' pyproject.toml | head -1)
  uvx copier copy --trust --skip-tasks --defaults --overwrite \
    -d project_name="$repo" -d description="$desc" \
    -d author_name="$(git config user.name)" -d author_email="$(git config user.email)" \
    "$dotfiles_dir/python" "$T"
fi

git -C "$T" init -q -b _retrofit-src
git -C "$T" add -A
git -C "$T" -c core.hooksPath=/dev/null commit -qm "governance template output"

# Fetch into an explicit temp ref, not FETCH_HEAD — in a linked worktree the
# FETCH_HEAD the fetch writes and the one merge resolves can differ (a stale
# shared entry made the merge silently no-op as "Already up to date").
git fetch -q "$T" _retrofit-src:refs/heads/_retrofit-src
trap 'rm -rf "$T"; git branch -qD _retrofit-src 2>/dev/null || true' EXIT
# --no-ff: some setups pin merge.ff=only, which hard-fails a real merge.
if git merge --allow-unrelated-histories --no-ff \
  -m "chore: retrofit governance templates" _retrofit-src; then
  echo
  echo "retrofit merged clean — review the diff, then run: lefthook install"
else
  echo
  echo "retrofit staged with conflicts (both contents kept, yours above the markers):"
  git diff --name-only --diff-filter=U | sed 's/^/  /'
  echo "resolve them, commit, then run: lefthook install"
fi
