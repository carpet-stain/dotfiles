# Backlog Manager Memory — carpet-stain/dotfiles

Load user-profile every session; the rest on topic relevance. Generic operating discipline
(ground-in-state, forcing-functions, dedupe-on-open) lives in `backlog-manager.md` itself now, not
here — this tier holds only what's specific to this repo/user.

## How we work
- [User profile](user_profile.md) — solo dotfiles dev, timeline-free, wants direct pushback, DRY-obsessed; the backlog-only lane
- [Single source of truth](feedback_single_source_of_truth.md) — user's core lens: point at enforced config, don't restate; signpost-vs-spec

## Backlog mechanics
- [gh conventions](gh_conventions.md) — labels, theme/priority/milestone axes, epic sub-issue gh gotchas, worktree-Write guard

## Initiatives (decision records — live status lives on the issue)
- [Python starter #129](project_python_starter.md) — reproducible py3 starter (uv+ruff+pyright+pytest+lefthook+CI) via copier; nvim-compat constraint
- [Git-flow governance #136](project_gitflow_starter.md) — portable git workflow/branch-protection/labels; compose-agents ports prose only; sibling of #129

## Environment
- [Claude Code paths & ~/.claude leak](env_claude_paths.md) — where CC writes; the daemon/telemetry leak is upstream (#134), not the subagent
