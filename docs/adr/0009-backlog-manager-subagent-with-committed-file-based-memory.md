# 9. Backlog-manager subagent with committed file-based memory

Date: 2026-07-10

## Status

Accepted

## Context

Issue/backlog work in this repo is a whole domain the user wanted to hand off
rather than micromanage — writing, labeling, prioritizing, grooming, and driving
issues to a good standard (#99). A subagent handles that, but its value depends
on retaining each repo's label taxonomy, prior grooming decisions, priority
rationale, and current backlog shape instead of relearning every session (#99
"Persistence across sessions"; backlog-manager.md "Memory").

Claude Code's `memory: project` gives it a per-repo memory dir, but that memory
started out untracked — not gitignored (it would commit if added), but not in
git either: local-only, no backup, no cross-machine sync, no version history of
the backlog decisions it records (#159). The memory system's stated intent is
version-controlled, shared memory (#159), and it holds the durable half of
"write it down over memory" — the reasoning behind a decision, not just the
decision (backlog-manager.md "Memory"). The subagent has no git access and its
lane stops at issues/labels/memory content, so it can't commit the memory itself
(#159; claude/README.md). A policy had to settle whether and how that memory is
version-controlled.

## Decision

Ship a dedicated `backlog-manager` subagent (`claude/agents/backlog-manager.md`;
model `opus`, tools Bash/Read/Grep/Glob, `memory: project`), deployed user-level
by symlinking `claude/agents/` into `$CLAUDE_CONFIG_DIR/agents/` in both deploy
scripts (#99, #100).

Persist its decisions to file-based memory under
`.claude/agent-memory/backlog-manager/`, and track that memory in git rather
than gitignore it (#159, 5b0f5f10). Split by portability: a rule that holds for
the subagent in any repo lives in the hand-reviewed, symlinked definition;
repo/user-specific facts (issue numbers, this repo's labels, this user's
preferences) stay as committed memory (claude/README.md, 5b0f5f10). Within the
memory tier, commit it whole — no further doc-like-vs-notes split, complexity a
solo repo doesn't need (claude/README.md, #159).

Whoever's in the repo commits it opportunistically, batched at the end of a
substantive session or after a grooming sweep, not per-tweak, via one
low-ceremony `chore(claude): sync <agent> memory` through the normal branch →
draft PR → squash → rebase-merge flow (#159, claude/README.md). Exclude
`.claude/agent-memory/**` from the markdownlint/prettier hooks, same as
CHANGELOG.md (5b0f5f10, lefthook.yml).

## Alternatives considered

- **Keep backlog reasoning in ephemeral chat/context (no persisted memory)** —
  the agent would relearn each repo's label taxonomy, grooming decisions, and
  priority rationale every session; the point of handing off the domain is a
  backlog that stays trustworthy across sessions without re-deriving it (#99
  "Persistence across sessions"; backlog-manager.md "Memory").
- **Keep memory untracked (local-only, as it started)** — persists between
  sessions but has no backup, no cross-machine sync, and no version history of
  the backlog decisions it records; the memory system's intent is
  version-controlled, shared memory (#159).
- **Gitignore the memory dir** — it's the durable half of "write it down over
  memory," version-controlled like everything else the subagent's judgment
  shapes; gitignoring throws away the version history of why the backlog is
  shaped as it is (claude/README.md, #159).
- **Split memory: commit doc-like files, keep agent-authored user notes local**
  — named as an open sub-decision in #159 and rejected in favor of committing it
  whole; a per-file doc-vs-notes split is complexity a solo repo doesn't need
  (claude/README.md, #159).
- **Hold memory to the full markdown lint/format bar** — memory files are
  heredoc-authored working notes, not published prose; forcing
  prettier/markdownlint on them adds friction, so they're excluded like
  CHANGELOG.md (claude/README.md, #159).
- **A dedicated lighter commit lane for memory (skip the PR flow)** — memory
  isn't code, but it's small enough that a separate mechanism isn't worth it;
  batched commits ride the normal branch → PR → rebase-merge flow instead
  (claude/README.md, #159).
- **Have the subagent commit its own memory** — backlog-manager has no git
  access and its lane stops at issues/labels/memory content, not repo mutation;
  a human in the repo commits it opportunistically instead (claude/README.md,
  #159).

## Consequences

Backlog knowledge now survives sessions and machines, with a walkable history of
why the backlog is shaped as it is (#159). The portability split keeps portable
rules hand-reviewed in the definition and repo-specific facts in committed
memory, so the definition stays repo-agnostic (claude/README.md, 5b0f5f10).

Costs: memory is written via bash heredoc because the tracked dir sits inside
the checkout and trips the Write tool's worktree-isolation guard
(gh_conventions.md, env_claude_paths.md). Committing depends on a human
remembering to sync since the agent can't (#159, claude/README.md), so memory
can lag reality between sweeps (inferred). The lint exclusion means memory files
aren't format-checked (lefthook.yml).

Revisit if: the agent gains repo-write access (drop the human-commit step),
memory grows enough to justify a per-file split or a lighter commit lane, or
this goes multi-repo (the split line and deployment change). Unrelated:
`~/.claude` clutter is upstream #134, not caused by this subagent
(env_claude_paths.md).
