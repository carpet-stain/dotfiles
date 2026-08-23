#!/usr/bin/env bash
# Cross-repo dispatch digest (#457): what's pickable right now across the
# repos in REPOS, without three ad-hoc `gh issue list` queries per session.
# Pickable = open, carries a priority label, not blocked (union of the
# `blocked` label and an open native `blocked-by` link), and — for
# `architecture`/`epic`-gated issues — carries `plan-approved` too.
# `agent-ready` (needs zero human judgment) floats to its own section.
# Read-only; uses only the read scopes the routine `GH_TOKEN` already has.
set -euo pipefail

OWNER="carpet-stain"
# short-name:repo-name — add a repo by appending one line here.
REPOS=(
  "dotfiles:dotfiles"
  "template:project-starter-template"
  "infra:infra"
  "memory:agent-memory-server"
  "agents:agents"
)

# Line budget: keeps the whole digest under 25 lines even with a large
# backlog (see AGENTS.md's Design Principles — reader-first, no JSON dump).
MAX_AGENT_READY=5
MAX_READY=11

combined="$(
  for entry in "${REPOS[@]}"; do
    repo="${entry#*:}"
    short="${entry%%:*}"
    gh issue list --repo "$OWNER/$repo" --state open \
      --json number,title,labels,blockedBy --limit 200 |
      jq --arg repo "$short" 'map(. + {repo: $repo})'
  done | jq -s 'add // []'
)"

echo "work queue — verify each plan's named preconditions against live state before implementing; a drifted precondition bounces to triage, not improvisation."
echo

jq -r --argjson agent_max "$MAX_AGENT_READY" --argjson ready_max "$MAX_READY" '
  def label_names: [.labels[].name];
  def has_label($n): (label_names | index($n)) != null;
  def priority_rank:
    if has_label("priority: high") then 0
    elif has_label("priority: medium") then 1
    elif has_label("priority: low") then 2
    else 99 end;
  def priority_tag:
    if has_label("priority: high") then "high"
    elif has_label("priority: medium") then "medium"
    elif has_label("priority: low") then "low"
    else "none" end;
  def gated: has_label("architecture") or has_label("epic");
  # Union, not swap (infra#309): the `blocked` label is a first-class signal for
  # blockers with no native representation, alongside open `blocked-by` links.
  def has_open_native_blocker: (.blockedBy.nodes // []) | any(.state == "OPEN");
  def is_blocked: has_label("blocked") or has_open_native_blocker;
  def pickable: (priority_rank != 99) and (is_blocked | not)
    and ((gated | not) or has_label("plan-approved"));
  def clip: if (.title | length) > 72 then .title[0:71] + "…" else .title end;

  (map(select(pickable and has_label("agent-ready"))) | sort_by(priority_rank)) as $agent_ready |
  (map(select(pickable and (has_label("agent-ready") | not))) | sort_by(priority_rank)) as $ready |
  (map(select(is_blocked)) | sort_by([.repo, .number])) as $blocked |

  (if ($agent_ready | length) > 0 then
    "AGENT-READY (mechanical, verified acceptance):",
    ($agent_ready[0:$agent_max][] | "  \(.repo)#\(.number)  \(clip)"),
    (if ($agent_ready | length) > $agent_max
      then "  (\($agent_ready | length - $agent_max) more...)" else empty end),
    ""
  else empty end),
  (if ($ready | length) > 0 then
    "READY (plan-approved / triaged, by priority):",
    ($ready[0:$ready_max][] | "  \(.repo)#\(.number) [\(priority_tag)] \(clip)"),
    (if ($ready | length) > $ready_max
      then "  (\($ready | length - $ready_max) more...)" else empty end),
    ""
  else empty end),
  (if ($blocked | length) > 0 then
    "BLOCKED: " + ($blocked[0] | "\(.repo)#\(.number) \(clip)")
      + (if ($blocked | length) > 1
          then " (\($blocked | length - 1) more...)" else "" end)
  else "BLOCKED: none"
  end)
' <<<"$combined"
