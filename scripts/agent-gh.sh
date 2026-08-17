#!/usr/bin/env bash
# agent-gh <backlog-manager|plan-reviewer> -- <cmd...> — run one command as a
# deliberation agent's GitHub machine account (carpet-stain-<name>), so its
# posts attribute to the agent, not the maintainer (#540, ADR-0035). Fetches
# the account's classic PAT (public_repo — fine-grained PATs can't write to
# another user's repos as a collaborator, #540) from SSM /runtime/<name>-pat
# (hand-populated, infra#173) with the same infra-local-read Keychain credential as
# aws-vended-token.sh, then execs the command with BOTH GH_TOKEN and
# GITHUB_TOKEN set — gh reads both, and .envrc exports both ambiently, so
# overriding only one would silently post as the maintainer (#160/#213).
# Before running anything it asserts `gh api user.login` matches the expected
# account — a wrong or rotated-out PAT fails loud, never mis-attributes. The
# PAT lives only in this process and the child; the calling shell's ambient
# identity (the maintainer's vended token) is untouched.
set -euo pipefail

usage() {
  echo "usage: agent-gh <backlog-manager|plan-reviewer> -- <cmd> [args...]" >&2
  exit 2
}

name=${1:-}
case $name in
  backlog-manager | plan-reviewer) ;;
  *) usage ;;
esac
[[ ${2:-} == -- ]] || usage
shift 2
(($#)) || usage

item=infra-aws-local-read
if ! secret=$(security find-generic-password -s "$item" -w 2>/dev/null); then
  echo "agent-gh: Keychain item '$item' missing or unreadable — see docs/credentials.md for the one-time setup" >&2
  exit 1
fi
key_id=$(security find-generic-password -s "$item" 2>/dev/null |
  sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
if [[ -z $key_id ]]; then
  echo "agent-gh: Keychain item '$item' has no acct attribute (should hold the access key id)" >&2
  exit 1
fi

# AWS credentials live only inside the fetch subshell — they never reach the
# wrapped command. Region pinned as in aws-vended-token.sh (infra ADR-0010).
pat=$(
  export AWS_ACCESS_KEY_ID=$key_id AWS_SECRET_ACCESS_KEY=$secret
  export AWS_REGION=us-east-1
  unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null || true
  aws ssm get-parameter --name "/runtime/$name-pat" --with-decryption \
    --query Parameter.Value --output text
)
if [[ -z $pat ]]; then
  echo "agent-gh: /runtime/$name-pat came back empty — infra#173's runbook (infra docs/BOOTSTRAP.md §13) populates it" >&2
  exit 1
fi

expected="carpet-stain-$name"
login=$(GH_TOKEN=$pat GITHUB_TOKEN=$pat gh api user --jq .login)
if [[ $login != "$expected" ]]; then
  echo "agent-gh: /runtime/$name-pat authenticates as '$login', expected '$expected' — refusing to run" >&2
  exit 1
fi

exec env GH_TOKEN="$pat" GITHUB_TOKEN="$pat" "$@"
