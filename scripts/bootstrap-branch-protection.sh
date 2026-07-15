#!/usr/bin/env bash
# Idempotent branch-protection ruleset bootstrap for the short-lived-branch +
# rebase-merge model (git.md/github.md): a `pull_request` rule restricted to
# rebase-merge, plus `deletion`/`non_fast_forward`, plus required status
# checks. Run from inside the target repo's checkout.
#
# Also asserts the legacy classic branch-protection rule absent: GitHub
# enforces classic protection AND rulesets together, taking the most
# restrictive of the two, so a lingering legacy rule silently overrides the
# ruleset (a legacy strict:true beats the ruleset's strict:false, forcing every
# green PR to "Update branch" and re-run CI before merge — #185). Deleting it
# here makes the ruleset the single source of truth and stops the drift
# recurring.
#
# Needs Administration scope, which the routine scoped GH_TOKEN deliberately
# lacks — run with `env -u GH_TOKEN -u GITHUB_TOKEN` so gh falls back to a
# full-admin session. Both vars must drop: `.envrc` aliases GITHUB_TOKEN to the
# same scoped token (for git-cliff) and gh prefers GITHUB_TOKEN, so dropping
# GH_TOKEN alone silently keeps the scoped token active (#213). Never wire this
# into CI or a copier post-gen task: it must stay a deliberate, human-invoked
# step, separate from the routine credential.
#
# usage: scripts/bootstrap-branch-protection.sh [branch] [extra-check ...]
#   branch        protected branch (default: repo's default branch)
#   extra-check   additional required status check name, repeatable
#                 (e.g. "lint" — CI job names vary per repo/language;
#                 "single commit" and "conventional commit" are always
#                 required since they come from the pr-guards.yml template
#                 verbatim, and "adr guard" is added automatically when
#                 .github/workflows/adr-guard.yml is present)
#
# Free-tier gotcha: GitHub rulesets need GitHub Pro or a public repo — a
# private repo 403s until upgraded or made public.
#
# Future direction: once repos-as-code work lands (Terraform, github
# provider — not yet started), replace this with a `github_repository_ruleset`
# resource for plan/apply diffing and drift detection across bootstrapped
# repos instead of this one-off "create or silently no-op" script per repo.
# Keep this script only as the interim mechanism until that lands.

set -euo pipefail

if [[ $# -ge 1 ]]; then
  BRANCH="$1"
  shift
else
  if ! BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>&1); then
    echo "error: failed to detect the default branch — check gh auth." >&2
    echo "retry with: env -u GH_TOKEN -u GITHUB_TOKEN $0 [branch] [extra-check ...]" >&2
    exit 1
  fi
fi
EXTRA_CHECKS=("$@")

RULESET_NAME="protect ${BRANCH}"

if ! RULESETS_JSON=$(gh api "repos/{owner}/{repo}/rulesets" 2>&1); then
  echo "error: failed to list rulesets — likely missing Administration scope." >&2
  echo "retry with: env -u GH_TOKEN -u GITHUB_TOKEN $0 ${BRANCH} ${EXTRA_CHECKS[*]}" >&2
  exit 1
fi

EXISTING_ID=$(echo "$RULESETS_JSON" | jq -r --arg name "$RULESET_NAME" '.[] | select(.name == $name) | .id')

# pr-guards.yml ships in every template repo, so its two checks are always
# required. adr-guard.yml's check is required too — but only where the guard
# actually ships: gate on the file so re-running this on a repo that opts out
# (dotfiles itself, per #241's Deferral) doesn't pin a required check that
# never reports and would block every PR.
REQUIRED_CHECKS=("single commit" "conventional commit")
if [[ -f .github/workflows/adr-guard.yml ]]; then
  REQUIRED_CHECKS+=("adr guard")
fi

CHECKS_JSON=$(printf '%s\n' "${REQUIRED_CHECKS[@]}" "${EXTRA_CHECKS[@]}" |
  jq -R '{context: .}' | jq -s '.')

PAYLOAD=$(jq -n --arg name "$RULESET_NAME" --argjson checks "$CHECKS_JSON" '{
  name: $name,
  target: "branch",
  enforcement: "active",
  conditions: {
    ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] }
  },
  rules: [
    { type: "pull_request", parameters: {
        required_approving_review_count: 0,
        dismiss_stale_reviews_on_push: false,
        required_reviewers: [],
        require_code_owner_review: false,
        require_last_push_approval: false,
        required_review_thread_resolution: false,
        allowed_merge_methods: ["rebase"]
    }},
    { type: "deletion" },
    { type: "non_fast_forward" },
    { type: "required_status_checks", parameters: {
        strict_required_status_checks_policy: false,
        do_not_enforce_on_create: false,
        required_status_checks: $checks
    }}
  ]
}')

if [[ -n "$EXISTING_ID" ]]; then
  echo "ruleset '$RULESET_NAME' exists (id $EXISTING_ID) — updating."
  echo "$PAYLOAD" | gh api "repos/{owner}/{repo}/rulesets/${EXISTING_ID}" -X PUT --input - >/dev/null
else
  echo "ruleset '$RULESET_NAME' not found — creating."
  echo "$PAYLOAD" | gh api "repos/{owner}/{repo}/rulesets" -X POST --input - >/dev/null
fi

# Clear the legacy classic branch-protection rule now that the ruleset above is
# in place — do it after, so `$BRANCH` is never left with neither system
# protecting it. GET distinguishes "protection exists" (200) from "not
# protected" (404) reliably; DELETE on an unprotected branch 403s, so gate on
# the GET rather than swallowing a blind DELETE's error. Ruleset-only from here.
if gh api "repos/{owner}/{repo}/branches/${BRANCH}/protection" >/dev/null 2>&1; then
  echo "legacy classic protection present on '${BRANCH}' — deleting (ruleset is source of truth)."
  gh api --method DELETE "repos/{owner}/{repo}/branches/${BRANCH}/protection" >/dev/null
else
  echo "no legacy classic protection on '${BRANCH}' — ruleset is sole source of truth."
fi

echo "done: $RULESET_NAME"
