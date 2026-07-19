# 31. Length-based advisory lint for comment concision

Date: 2026-07-19

## Status

Accepted

## Context

`design-principles.md` already says comments explain why, not what, and that
when the why is recoverable elsewhere a pointer beats restating it — but
nothing mechanically checked this. infra#38's `app.tf` restated a repo-wide
fact ("runs under the elevated session, same as every other
Administration-scope apply") already in that repo's own README.md/AGENTS.md —
the rule was correct, it just wasn't enforced, so it got missed (#374). This
repo is the reference implementation two other repos (infra,
project-starter-template) mirror (#374/#375), so the design needs to hold up,
not just work once.

## Decision

A lefthook job (`scripts/check-comment-concision.sh`, wired into
`lefthook.yml` as `comment-concision`) flags a comment block over
`THRESHOLD_LINES` (20) lines attached to a single declaration, printing an
advisory nudge — never a non-zero exit — pointing at
`design-principles.md`'s pointer rule. It excludes a file's leading
header/preamble block (starts at line 1, or line 2 right after a shebang),
since those are legitimate standalone documentation, not a per-declaration
comment. 20 is not a guess: this repo's densest existing legitimate
single-declaration comment (`linux/deploy.sh`'s `generate_ghostty_terminfo`
block) is 15 lines, so the threshold sits with headroom above the real
observed max — calibrated against this repo's actual dense-but-non-redundant
style, per #375's "err toward under-flagging over crying wolf."

## Alternatives considered

- **Phrase-overlap against this repo's own README.md/AGENTS.md** — the
  redundant infra#38 sentence shares short phrases ("elevated session",
  "Administration scope") with infra's own docs, so a grep-style "does this
  comment phrase already appear in the docs" check looked like it could
  directly catch that regression instead of falling back on length. Tested
  two independent tunings against this repo's real files, not just the
  synthetic worked example: a 3-word sliding-window match (the minimum
  window that catches the real infra#38 phrase) flags nearly every dense
  comment block in this repo, including `linux/deploy.sh`'s and
  `macos/deploy.zsh`'s own `see CLAUDE's README` pointers — i.e. it flags the
  exact "point at it instead of restating" pattern the rule wants to
  encourage, the worst possible false positive. A directional
  significant-word-overlap-per-corpus-line variant (near-duplicate-sentence
  matching) does no better — small corpus lines spike to high overlap ratios
  by chance (e.g. an unrelated Catppuccin doc line "matching" an unrelated
  Catppuccin comment). Both fail for the same structural reason: this repo's
  comments intentionally echo doc vocabulary because it's already
  well-cross-referenced, and no bag-of-words/n-gram method can tell that
  apart from genuine restatement without semantic understanding — which
  #374 rules out (not an LLM-based check, for cost and always-on coverage).
- **LLM-based semantic redundancy check** — ruled out by #374's own
  non-goals: cost and always-on-every-commit coverage both push toward a
  mechanical heuristic; this repo already has an LLM-based PR-review layer
  (ADR-0025) for judgment calls, so duplicating that cheaply per-commit isn't
  the goal here.

## Consequences

The lint cannot catch infra#38's actual regression: the redundant sentence
was 1 line embedded in an 8-line block, and even split into its own
paragraph the load-bearing/redundant halves are 4 and 2 lines respectively —
both well under any threshold high enough to avoid false-positiving on this
repo's own legitimate dense comments (verified: the check runs silent
across this entire repo's `.zsh`/`.sh`/`.lua` files as of this ADR). Length
alone is not a redundancy detector, only an outlier-size nudge; catching a
short, already-documented restatement stays a human/PR-review concern, not
this lint's job. infra's and project-starter-template's versions (#374's
other children) should mirror this same shape — advisory only, exclude file
headers, calibrate `THRESHOLD_LINES` against each repo's own real dense
comments rather than reusing 20 verbatim if their style differs (e.g. `.tf`
comments may run denser or leaner than this repo's zsh/lua/bash). Revisit if
a cheap, low-false-positive way to catch short restated-elsewhere content
ever surfaces — nothing tried here cleared the bar.
