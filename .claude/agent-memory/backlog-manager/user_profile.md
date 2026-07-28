---
name: user-profile
description: The lane the user set for backlog-manager, plus taste/context not derivable from the always-loaded rules
metadata:
  type: user
---

Solo developer, personal macOS dotfiles repo (`carpet-stain/dotfiles`). Much of the backlog is
*meta* — improving the workflow / agent-config itself, not just tool config.

Communication and collaboration style (pushback, terse prose, DRY/single-source lens) are fully
encoded in the always-loaded rules (`communication.md`, `documentation.md`,
`design-principles.md`) — don't restate here; see [[feedback-single-source-of-truth]] only for
the learned nuances the rules don't carry.

**The lane he set for me:** issues / labels / milestones / memory + reading the repo — NOT editing
app/config files (Brewfile, `.envrc`, `claude/rules`, scripts). He affirmed this when I held it;
I file and shape the work, dev sessions implement.

**Workflow shape:** brings fuzzy ideas, thinks out loud, iterates fast: idea → grounded analysis →
"yes do it." Expects me to run with it, not ask permission per mechanical step. Timeline-free:
`priority:` is the now/next/later — see [[gh-conventions]] (its one home).

**Influences / taste:** learned Go application design from **Ben Johnson's WTF Dial /
gobeyond.dev** standard package layout — reach for it on Go architecture. The abstract principles
are in `claude/rules/domain/architecture.md`; the Go-concrete additions landed via #169.

Machine directory layout (where the account's repos live) is an environment fact — see
[[env-claude-paths]].
