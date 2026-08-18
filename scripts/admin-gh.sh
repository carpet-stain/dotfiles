#!/usr/bin/env bash
# admin-gh <args...> — run gh with GitHub's admin fine-grained PAT
# (Administration/Issues/Variables, all repos — infra ADR-0013) exported as
# GITHUB_TOKEN, no infra checkout required. Fetches /infra/gh-admin-token
# from SSM behind the same prompt-gated infra-aws-local-apply Keychain item
# `with-infra-secrets.sh --gh-admin` uses locally (infra's script), so the
# crown-jewel gate is unchanged: a human clicks Allow on the Keychain
# prompt, a non-interactive/agent shell fails closed. `gh auth switch` /
# `login --with-token` was rejected — either persists the admin token in
# gh's keyring as an unlocked ambient fallback, defeating the on-demand
# gate (infra ADR-0013). GH_TOKEN is dropped (gh prefers it over
# GITHUB_TOKEN, same footgun as infra-gh #213) so the admin token actually
# wins. No GH_REPO default — admin is cross-repo; pass -R explicitly
# (unlike infra-gh #647).
set -euo pipefail

# Account attribute doesn't prompt; the secret (-w) does — the one gated
# read per item, same order as infra's with-infra-secrets.sh.
item=infra-aws-local-apply
aws_key_id="$(security find-generic-password -s "$item" 2>/dev/null | awk -F'"' '$2 == "acct" {print $4}')"
if ! aws_secret="$(security find-generic-password -s "$item" -w 2>/dev/null)"; then
  echo "admin-gh: Keychain item '$item' missing or unreadable — see infra docs/BOOTSTRAP.md" >&2
  exit 1
fi
[[ -n $aws_key_id ]] || {
  echo "admin-gh: Keychain item '$item' has no acct attribute (should hold the access key id)" >&2
  exit 1
}

# AWS credentials live only inside this fetch subshell — they never reach
# the wrapped command. Region pinned as in with-infra-secrets.sh.
token=$(
  export AWS_ACCESS_KEY_ID=$aws_key_id AWS_SECRET_ACCESS_KEY=$aws_secret
  export AWS_REGION=us-east-1
  unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null || true
  aws ssm get-parameter --name /infra/gh-admin-token --with-decryption \
    --query Parameter.Value --output text
)
if [[ -z $token || $token == PLACEHOLDER ]]; then
  echo "admin-gh: /infra/gh-admin-token came back empty or PLACEHOLDER — see infra ADR-0013" >&2
  exit 1
fi

exec env -u GH_TOKEN GITHUB_TOKEN="$token" gh "$@"
