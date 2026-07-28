# Backlog Manager Memory — carpet-stain/dotfiles

Load user-profile every session; the rest on topic relevance. Generic operating discipline lives
in `backlog-manager.md`; the content contract is ADR-0033 (memory is a pointer layer — decisions,
whys, pointers, lessons; live status lives on the issue, always).

## How we work
- [User profile](user_profile.md) — the backlog-only lane, workflow shape, Go taste; style prefs live in the rules, not here
- [Single source of truth](feedback_single_source_of_truth.md) — SSOT lens graduated into the rules; keeps only over-correction + inward-layer nuances

- [Template propagation](feedback_template_propagation.md) — git/CI/md-lint/justfile/lefthook changes in dotfiles must propagate to project-starter-template

## Backlog mechanics
- [gh conventions](gh_conventions.md) — labels, theme/priority axes, epic sub-issue gh gotchas, sweep disciplines
- [map: carpet-stain/infra](map_infra.md) — cross-repo map entry (its facts live in its own store; ADR-0033 Residency)
- [map: project-starter-template](map_project-starter-template.md) — cross-repo map entry
- [Memory-PR automation](project_memory_pr_automation.md) — memory-system redesign (epic #419, ADR-0032/0033); skill-vs-agent isolation + sync-PR lessons

## Initiatives (decision records — live status lives on the issue)
- [Python starter](project_python_starter.md) — template extracted; ADR-0014 owns the decision
- [Git-flow governance](project_gitflow_starter.md) — extraction lessons (compose-agents is prose-only; ruleset↔check-name coupling); ADR-0028 owns the decision
- [Terraform repos-as-code](project_terraform_repos_as_code.md) — TF work belongs in infra, not dotfiles; ADR-0022/0023/0024 own the decisions
- [Agent-config adoption](project_agent_config_adoption.md) — the borrow-filter for external claude setups; what's deliberately rejected
- [Tier split](project_tier_split_127.md) — three-tier model ratified by spike #127, executed via #361; the spike's decision comment is the source
- [Deal Finder](project_deal_finder.md) — pre-repo; creation routes through infra, backlog gets built once it exists

## Environment
- [Claude Code paths & ~/.claude leak](env_claude_paths.md) — where CC writes; the daemon/telemetry leak is upstream (#134), not the subagent
