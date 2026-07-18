#!/usr/bin/env bash
# Render-then-lint for the copier templates (git-flow base, git-flow+python
# overlay) — see dotfiles#310. The .jinja/copier syntax breaks yaml/toml/py
# parsers directly, so this validates the *rendered output* with the same
# linters the repo already runs, instead of parsing the raw template files.
#
# Usage:
#   lint-templates.sh              full render-then-lint (just lint-templates, CI)
#   lint-templates.sh --jinja F...  raw j2lint pass over F... (lefthook pre-commit,
#                                   passed {staged_files}) — cheap, no render
#
# Two renders in the default mode: base alone, and base+python layered
# (mirrors the two real scaffolding paths — a language-agnostic repo, and a
# Python one). Each render's file list comes from `git ls-files` after
# `git add -A`, so a rendered repo's own `.gitignore` (which excludes
# `.venv`, etc.) does the same exclusion work a real commit would — no
# separate glob-exclude list to maintain here.
set -euo pipefail

# Run via lefthook's pre-push hook, GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE are
# set to *this* repo's git dir for the hook's own use — but copier's `git`
# calls (resolving a template source's latest tag) inherit them too, and a
# GIT_DIR pinned to the wrong repo makes `git ls-remote` on the template
# path itself fail with "does not appear to be a git repository". Unset
# before any copier invocation so its internal git calls see plain ambient
# state, same as running this script by hand.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_PREFIX 2>/dev/null || true

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

fail=0

# j2lint_pass F...  ->  raw jinja syntax check on any *.jinja files in F...
#
# Two known false-positive classes are dropped here, not linted at all
# (both are caught for real by the render-then-lint pass instead):
#   - cliff.toml.jinja embeds git-cliff's own Tera template inside a Jinja
#     `{% raw %}` block; j2lint doesn't know to skip raw-block contents and
#     misreads Tera's {{ }}/{% %} as malformed Jinja.
#   - release-prepare/publish.yml.jinja use GitHub Actions' own `${{ }}`
#     syntax literally (this template remaps copier's variable delimiters to
#     `[[ ]]` in copier.yml's _envops specifically so `${{ }}` passes
#     through untouched) — j2lint doesn't know about that remap and misreads
#     `${{ secrets.X }}` as a plain Jinja variable.
j2lint_pass() {
  local jinja_files=()
  for f in "$@"; do
    case "$f" in
      *.jinja) ;;
      *) continue ;;
    esac
    case "$f" in
      *cliff.toml*.jinja) continue ;;
      *release-prepare.yml*.jinja | *release-publish.yml*.jinja) continue ;;
      *) jinja_files+=("$f") ;;
    esac
  done
  if [ "${#jinja_files[@]}" -gt 0 ]; then
    uvx j2lint "${jinja_files[@]}" || fail=1
  fi
}

if [ "${1:-}" = "--jinja" ]; then
  shift
  j2lint_pass "$@"
  exit "$fail"
fi

cleanup_dirs=()
cleanup() {
  for d in "${cleanup_dirs[@]}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

# render <template-dir> [copier -d/-- flags...]  ->  prints the render dir
render() {
  local template=$1
  shift
  local dir
  dir=$(mktemp -d)
  cleanup_dirs+=("$dir")
  uvx copier copy --trust --defaults "$@" "$template" "$dir" >&2
  git -C "$dir" add -A
  printf '%s\n' "$dir"
}

echo "==> j2lint (raw jinja syntax)"
mapfile -d '' all_jinja < <(find git-flow/template python/template -name "*.jinja" -print0)
j2lint_pass "${all_jinja[@]}"

lint_rendered() {
  local dir=$1
  local tracked
  mapfile -t tracked < <(git -C "$dir" ls-files)

  local workflows=() yaml_files=() toml_files=() md_files=() sh_files=() py_files=()
  for f in "${tracked[@]}"; do
    case "$f" in
      .github/workflows/*.yml | .github/workflows/*.yaml) workflows+=("$f") ;;
    esac
    case "$f" in
      .github/dependabot.yml | .markdownlint-cli2.yaml | lefthook.yml | lefthook-base.yml | lefthook-lang.yml)
        yaml_files+=("$f")
        ;;
    esac
    case "$f" in
      *.toml) toml_files+=("$f") ;;
      *.md) md_files+=("$f") ;;
      *.sh | .envrc | .envrc.local.example) sh_files+=("$f") ;;
      *.py) py_files+=("$f") ;;
    esac
  done

  if [ "${#workflows[@]}" -gt 0 ]; then
    (cd "$dir" && actionlint "${workflows[@]}") || fail=1
  fi
  if [ "${#yaml_files[@]}" -gt 0 ]; then
    (cd "$dir" && yamlfmt -lint "${yaml_files[@]}") || fail=1
  fi
  if [ "${#toml_files[@]}" -gt 0 ]; then
    # Structural validity only, not `taplo fmt --check`: taplo collapses a
    # short array to one line and keeps a long one expanded, and the
    # threshold is the *rendered* line length — which depends on the
    # answers (author name/email, description), not the template. No
    # static template text is fmt-stable for arbitrary answers, and the
    # generated repo doesn't wire toml formatting into its own lefthook
    # config either, so this would flag an inherent property of
    # jinja-templated TOML, not a template defect.
    (cd "$dir" && taplo lint "${toml_files[@]}") || fail=1
  fi
  if [ "${#md_files[@]}" -gt 0 ]; then
    (cd "$dir" && markdownlint-cli2 "${md_files[@]}") || fail=1
    (cd "$dir" && prettier --check "${md_files[@]}") || fail=1
  fi
  if [ "${#sh_files[@]}" -gt 0 ]; then
    (cd "$dir" && shellcheck "${sh_files[@]}") || fail=1
  fi
  if [ "${#py_files[@]}" -gt 0 ]; then
    (cd "$dir" && uv run ruff check . && uv run ruff format --check . && uv run pyright) || fail=1
  fi
}

echo "==> rendering + linting git-flow (base only)"
base_dir=$(render git-flow -d github_owner=fixture-owner -d github_repo=fixture-repo)
lint_rendered "$base_dir"

echo "==> rendering + linting git-flow + python overlay"
overlay_dir=$(render git-flow -d github_owner=fixture-owner -d github_repo=fixture-repo)
uvx copier copy --trust --defaults --overwrite \
  -d project_name="Fixture Project" \
  -d description="A fixture project for template lint validation." \
  -d author_name="Fixture Author" \
  -d author_email="fixture@example.com" \
  python "$overlay_dir" >&2
git -C "$overlay_dir" add -A
lint_rendered "$overlay_dir"

if [ "$fail" -ne 0 ]; then
  echo "lint-templates: FAILED" >&2
  exit 1
fi
echo "lint-templates: clean"
