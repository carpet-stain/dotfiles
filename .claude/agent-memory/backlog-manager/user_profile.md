---
name: user-profile
description: Who the user is and how they collaborate — solo dotfiles dev, wants pushback, DRY-obsessed, holds the backlog-manager lane
metadata:
  type: user
---

Solo developer, personal macOS dotfiles repo (`carpet-stain/dotfiles`). Sophisticated setup: a
global agent-config system (`claude/rules`, skills, AGENTS.md) and a rigorous git workflow
(draft-PR-early, rebase-merge, conventional commits, git-cliff releases). Much of the backlog is
*meta* — improving the workflow / agent-config itself, not just tool config.

**Collaboration style:**
- Brings fuzzy ideas or questions, thinks out loud, iterates fast: idea → my grounded analysis →
  "yes do it." Expects me to run with it, not ask permission per mechanical step.
- **Wants direct pushback.** Explicitly asks "does this make sense or am I off?" and values being
  told when he's wrong, with the reason — more than agreement. Hedging or flattery is a disservice.
- Reasons from his own philosophy as the lens: single-source-of-truth / DRY / Configuration-is-Code
  / signpost-not-restate / work-through-human-toolchains. Tie recommendations to these.
  See [[feedback-single-source-of-truth]].
- **Timeline-free by preference** — no dates, milestones aren't releases; `priority:` is his
  now/next/later. See [[gh-conventions]].
- Prefers terse, concrete, opinionated prose; no filler or AI-writing tells.

**Influences / taste:** learned Go and Go application design from **Ben Johnson's WTF Dial /
gobeyond.dev** "standard package layout" (domain-root package, group-by-dependency subpackages,
interfaces-in-the-consumer, `cmd/` thin main, `Error{Code,Message}`). Likes his thinking — reach for
it on Go architecture. Their `claude/rules/domain/architecture.md` already encodes the abstract
principles; #169 tracks the Go-concrete additions to go.md.

**The lane he set for me:** issues / labels / milestones / memory + reading the repo — NOT editing
app/config files (Brewfile, `.envrc`, `claude/rules`, scripts). He affirmed this when I held it;
I file and shape the work, dev sessions implement.
