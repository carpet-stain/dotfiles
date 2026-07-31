#!/usr/bin/env bash
# Advisory pre-push nudge (#493): a change to a governance surface (CI
# workflows, lefthook.yml, justfile, cliff.toml, root lint configs) must be
# evaluated for propagation to carpet-stain/project-starter-template — the
# governance source for every future repo. Observed to rot silently twice
# (gitleaks -> template#26, dependabot labels -> template#25) before this
# rule was even stated (#449). Broad globs, not a hand-maintained file list,
# so a new governance file doesn't silently fall outside the check.
#
# Known blind spot, accepted: this fires on any touch to these files,
# including a no-op edit, and can't verify a propagation issue was actually
# filed — it only nudges. Deploy scripts are deliberately not in this list:
# per agent memory, they don't propagate to the template.
set -uo pipefail

if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  echo "check-governance-propagation: skipped: no origin/main ref"
  exit 0
fi

changed="$(git diff --name-only origin/main...HEAD)"

governance_pattern='^(\.github/workflows/.*|lefthook\.yml|justfile|cliff\.toml|\.editorconfig|\.gitleaks\.toml|\.markdownlint-cli2\.ya?ml)$'

if grep -qE "$governance_pattern" <<<"$changed"; then
  echo "check-governance-propagation: this branch touches a governance surface — evaluate propagating to carpet-stain/project-starter-template (AGENTS.md)"
fi

exit 0
