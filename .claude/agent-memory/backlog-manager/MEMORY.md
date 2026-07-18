# Backlog Manager Memory — carpet-stain/dotfiles

Load user-profile every session; the rest on topic relevance. Generic operating discipline
(ground-in-state, forcing-functions, dedupe-on-open) lives in `backlog-manager.md` itself now, not
here — this tier holds only what's specific to this repo/user.

## How we work
- [User profile](user_profile.md) — solo dotfiles dev, timeline-free, wants direct pushback, DRY-obsessed; the backlog-only lane
- [Single source of truth](feedback_single_source_of_truth.md) — user's core lens: point at enforced config, don't restate; signpost-vs-spec

## Backlog mechanics
- [gh conventions](gh_conventions.md) — labels, theme/priority/milestone axes, epic sub-issue gh gotchas, worktree-Write guard
- [carpet-stain/infra](reference_infra_repo.md) — sibling GitHub-governance repo with its own backlog-manager memory; cross-repo dependency web to dotfiles #309/#311/#331

## Initiatives (decision records — live status lives on the issue)
- [Python starter #129](project_python_starter.md) — CLOSED; template extracted to project-starter-template (see ADR-0014, ADR-0028)
- [Git-flow governance #136](project_gitflow_starter.md) — CLOSED; both templates extracted to project-starter-template via epic #309 (see ADR-0028); compose-agents-ports-prose-only finding still load-bearing
- [Terraform repos-as-code #273](project_terraform_repos_as_code.md) — CLOSED 2026-07-18; OpenTofu repos-as-code moved to sibling repo carpet-stain/infra, which now owns continuation
- [Agent-config adoption #298](project_agent_config_adoption.md) — CLOSED 2026-07-18; all three children shipped (reviewer subagent #300, disclosure skill #299, activation-hook spike #301); CI-review automation lives on in #302

## Environment
- [Claude Code paths & ~/.claude leak](env_claude_paths.md) — where CC writes; the daemon/telemetry leak is upstream (#134), not the subagent
