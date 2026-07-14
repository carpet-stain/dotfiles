# 18. Signpost/spec documentation model: one home per fact, point elsewhere

Date: 2026-07-13

## Status

Accepted

## Context

Docs in this repo had no single rule for where a fact lives, so the same content
got restated in different words and drifted silently. AGENTS.md re-typed the
Conventional-Commit type list that pr-guards.yml already enforces byte-for-byte
(#140, 41110fab), and AGENTS.md and README.md stated philosophy / what-this-is /
the XDG principle near-verbatim in both (#187, 1b452260). Worse, major design
decisions — and, critically, what was considered and rejected — weren't
walkable: reconstructing "why X over Y" meant excavating scattered closed issues
and PRs, and this session alone made ~15 significant decisions with no
distilled, durable home (#204). engineering-practices.md already demanded "read
the recorded decisions… supersede explicitly rather than letting code and intent
drift," but named no concrete artifact realizing it (#204, af8b28e9).

The same signpost/spec problem recurred at every level: config↔doc (#140),
doc↔doc (#187), and code-comment↔provenance (#192), so a piecemeal fix at one
level would leave the others to drift. A stated map of what belongs where was
missing.

## Decision

One home per fact; everywhere else points, never restates. Encode a
documentation home map in AGENTS.md ("Documentation: one home per fact"): Issue
owns the plan / design / acceptance; PR owns the real-time journal; ADR owns the
distilled major decision plus rejected alternatives and consequences; AGENTS.md
owns how to work here and points at ADRs for the why; README owns what-it-is /
install / use; code comments own the tripwire-why at the point of edit plus a
pointer; configs own the enforced spec and are self-speaking.

Adopt ADRs under docs/adr/ with a lightweight Nygard template (Status / Context
/ Decision / Alternatives-considered-plus-why-rejected / Consequences), written
only for architecturally-significant, cross-cutting, long-lived, or
expensive-to-reverse decisions. Configs and enforcement (lefthook,
pr-guards.yml, cliff.toml, CI) are the spec; docs point at them and keep only
the why and workflow shape no config can hold (#140). Cover every fact in the
fewest words; each fact has one home, everything else points — and never point
back the other way (the circular-pointer trap).

## Alternatives considered

- **Full restatement across docs — let each doc spell out the spec itself (the
  prior state in #140 / #187)** — two sources of truth that drift silently, the
  worst kind because they diverge in different words instead of obviously; cuts
  against Configuration-Is-Code (the rule lives in the versioned config a tool
  reads) and work-through-human-toolchains (the enforcing gate, not the prose,
  is authoritative) (#140, #187).
- **Delete-not-point — drop all mention of an enforced rule once a config
  enforces it** — backfires: priming prose is the earliest, cheapest place to
  catch a mistake, and deletion pushes discovery to the most expensive point (a
  CI round-trip or blocked merge), which only says something is wrong, not
  what's preferred or why; also strips the human-facing guide. The cut is
  restate→point, not enforced→delete (#140).
- **Prune the abstract rules too — strip specs like the Conventional-Commit type
  list from claude/rules/\*.md** — that list is the COMPOSE template's fill
  material; strip it and composition breaks. At the rules layer you can't point
  at a config that doesn't exist yet, so the move is de-dup + tighten, not
  prune-to-zero (#142).
- **Offload the comment-why to git blame — treat "be stingier with comments" as
  license to move intent into history** — blame is forensics you reach for after
  you already suspect a problem; the comment is the tripwire that prevents it.
  Leveraging provenance means pointer, not omission — the load-bearing "removing
  this breaks X" stays inline at the point of edit (#192).
- **Add an abstract duplicate of the home-map table to the universal rules** —
  would re-create the exact doc↔doc duplication this decision warns against. The
  concrete home map stays repo-specific in AGENTS.md; the universal rules name
  ADR adoption and the one-home/pointer discipline abstractly, piecewise across
  design-principles.md and engineering-practices.md (#204 closing comment).

## Consequences

Major decisions and their rejected paths are now walkable in docs/adr/ instead
of requiring an excavation of closed issues and PRs; this backfill (#205) is the
first application. Each fact has one home, so de-dup passes have a rule to
enforce — audit-rules gained a cross-doc replication check (doc↔doc, #187)
alongside its restated-enforcement check (doc↔config, #140) to keep drift from
creeping back, and the AGENTS↔README de-dup already trimmed AGENTS.md by ~13
lines (1b452260, #187).

The tax: writing an ADR for significant decisions, and discipline against ADR
sprawl — small local choices stay in a PR or comment, not an ADR. Every pointer
now depends on its target staying put; a moved or renamed home breaks pointers,
and the circular-pointer trap (two docs each saying "see the other") has to be
watched (inferred from the one-home/pointer model). engineering-practices.md's
"recorded decisions" principle is realized by ADRs without repo-specific paths
(af8b28e9). Revisit if the git provenance chain that makes pointers cheap stops
holding, or if the config/doc/comment/ADR family grows a level the map doesn't
cover.
