#!/usr/bin/env bash
# infra-gh <args...> — run gh with the ambient vended GH_TOKEN/GITHUB_TOKEN
# dropped, falling back to gh's keyring dev PAT. Infra deliberately excludes
# itself from the vended token's repo allowlist (#51/infra ADR-0010 — a
# routine agent-reachable credential must never rewrite the governance that
# constrains it), so writes to carpet-stain/infra 403 under the ambient
# token. Both vars must drop together: .envrc aliases GITHUB_TOKEN=$GH_TOKEN,
# so unsetting only one leaves the vended token live in the other (#213).
# Ergonomics only — the vended token and its scope are untouched (#613).
# GH_REPO pins the target repo: with no -R, gh resolves from the cwd git
# remote, so a bare call from a non-infra checkout silently clobbered a
# same-numbered issue/PR there (#647). -R/--repo still overrides GH_REPO.
set -euo pipefail

exec env -u GH_TOKEN -u GITHUB_TOKEN GH_REPO=carpet-stain/infra gh "$@"
