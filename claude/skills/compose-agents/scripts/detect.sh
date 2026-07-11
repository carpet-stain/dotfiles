#!/usr/bin/env bash
# Best-effort repo-fact detection for the compose-agents skill. Run from the
# target repo's root. Emits KEY=value lines, one per field, always emitting
# the key even when the value is empty so the caller can tell "detected
# empty" from "field never ran". Read-only — never mutates repo or git
# state, safe to run repeatedly against any repo, including someone else's.
#
# Each field is independently guarded: a missing tool (e.g. no `gh`) or an
# unmet precondition only blanks that one field, never the rest — mirrors
# this repo's own required()/optional() split in macos/deploy.zsh and
# linux/deploy.sh.
set -uo pipefail

is_git_repo=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  is_git_repo=true
fi
echo "IS_GIT_REPO=$is_git_repo"

remote_host=""
if $is_git_repo; then
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  case "$origin_url" in
    *github.com*) remote_host="github.com" ;;
    *gitlab.com*) remote_host="gitlab.com" ;;
    *bitbucket.org*) remote_host="bitbucket.org" ;;
    "") remote_host="" ;;
    *) remote_host="other" ;;
  esac
fi
echo "REMOTE_HOST=$remote_host"

is_go_repo=false
if [[ -f go.mod ]] || find . -maxdepth 3 -name '*.go' -print -quit 2>/dev/null | grep -q .; then
  is_go_repo=true
fi
echo "IS_GO_REPO=$is_go_repo"

scopes=""
if $is_git_repo; then
  scopes="$(find . -maxdepth 1 -mindepth 1 -type d -not -path '*/.*' -exec basename {} \; |
    sort | paste -sd, -)"
fi
echo "SCOPES=$scopes"

version_scheme=""
if [[ -f cliff.toml ]]; then
  version_scheme="SemVer (git-cliff)"
elif $is_git_repo && git tag -l 2>/dev/null | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
  version_scheme="SemVer (git tags, no git-cliff detected)"
fi
echo "VERSION_SCHEME=$version_scheme"

release_automation=""
if [[ -d .github/workflows ]]; then
  release_automation="$(find .github/workflows -maxdepth 1 -iname '*release*' -exec basename {} \; |
    sort | paste -sd, -)"
fi
echo "RELEASE_AUTOMATION=$release_automation"

# Heuristic, not fact — flag as inferred to the caller. Looks for a workflow
# that gates PRs on both a single-commit count and a Conventional Commit
# subject, the signal this repo's own pr-guards.yml uses for its short-lived
# -feature-branch + squash-per-PR + rebase-merge model. git.md's own
# documented default is the long-lived-working-branch + squash-merge model;
# absent this signal, assume that default rather than guessing further.
branch_model="long-lived-working-branch+squash-merge (git.md default — no override signal found)"
if [[ -d .github/workflows ]] &&
  grep -rlqE 'pull_request\.commits' .github/workflows/*.y*ml 2>/dev/null &&
  grep -rlqE '\(feat\|fix\|docs\|style\|refactor\|perf\|test\|build\|ci\|chore\)' .github/workflows/*.y*ml 2>/dev/null; then
  branch_model="short-lived-feature-branch+squash-per-PR+rebase-merge (HEURISTIC — verify against the repo's actual docs)"
fi
echo "BRANCH_MODEL=$branch_model"

protected_branch=""
if $is_git_repo; then
  protected_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
  if [[ -z "$protected_branch" ]]; then
    for candidate in main master; do
      if git show-ref --verify --quiet "refs/remotes/origin/$candidate" ||
        git show-ref --verify --quiet "refs/heads/$candidate"; then
        protected_branch="$candidate"
        break
      fi
    done
  fi
fi
echo "PROTECTED_BRANCH=$protected_branch"

pre_commit_tool=""
if [[ -f lefthook.yml ]] || [[ -f lefthook.yaml ]]; then
  pre_commit_tool="lefthook"
elif [[ -f .pre-commit-config.yaml ]]; then
  pre_commit_tool="pre-commit (python)"
elif [[ -d .husky ]]; then
  pre_commit_tool="husky"
fi
echo "PRE_COMMIT_TOOL=$pre_commit_tool"

credential_pattern=""
if [[ -f .envrc.local.example ]] && grep -qE '(GH_TOKEN|_TOKEN|_KEY|_SECRET)' .envrc.local.example 2>/dev/null; then
  credential_pattern="direnv-scoped token (see .envrc.local.example)"
fi
echo "CREDENTIAL_PATTERN=$credential_pattern"

gh_available=false
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh_available=true
fi
echo "GH_AVAILABLE=$gh_available"

has_agents_md=""
[[ -f AGENTS.md ]] && has_agents_md="AGENTS.md"
echo "HAS_AGENTS_MD=$has_agents_md"

has_claude_md_symlink=""
if [[ -L CLAUDE.md ]]; then
  has_claude_md_symlink="$(readlink CLAUDE.md)"
fi
echo "HAS_CLAUDE_MD_SYMLINK=$has_claude_md_symlink"
