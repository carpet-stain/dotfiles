#!/usr/bin/env bash
# Retired (#528): agent-memory is gitignored and local-only — ADR-0036
# supersedes the rolling draft-PR sync (ADR-0027/0032). Exit-0 stub so
# session-end rituals still invoking `git memory-pr` don't error; full
# removal (script, alias, deploy symlink) is the rollout epic's job (#542).
echo "git memory-pr is retired — agent-memory is local-only (#528, ADR-0036); nothing to sync" >&2
exit 0
