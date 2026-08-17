# shellcheck shell=bash

# Shared vended-token bridge (infra#195, see docs/credentials.md).
# Caller must source .envrc.local before calling this.
use_github_token() {
  # aws-vended-token is macOS-only (Keychain-backed) — the guard makes this
  # a no-op on Linux rather than a missing-command error.
  if command -v security >/dev/null && security find-generic-password -s infra-aws-local-read >/dev/null 2>&1; then
    local vt
    if vt=$(aws-vended-token); then
      export GH_VENDED_TOKEN="$vt"
    else
      log_error "vended GitHub token unavailable (see the error above) — #377/infra#125"
    fi
  fi

  # Resolution order (#453, ADR-0041): .envrc.local wins,
  # else vended, else the sentinel — unconditional and last (#160).
  [[ -z "${GH_TOKEN:-}" && -n "${GH_VENDED_TOKEN:-}" ]] && export GH_TOKEN="$GH_VENDED_TOKEN"
  [[ -z "${GH_TOKEN:-}" ]] && export GH_TOKEN=vended-unavailable-see-453

  # git-cliff reads its GitHub API token from GITHUB_TOKEN, not GH_TOKEN —
  # alias rather than asking for a second credential.
  export GITHUB_TOKEN="$GH_TOKEN"
}
