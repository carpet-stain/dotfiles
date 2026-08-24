# 40. Per-repo backlog with a virtual multi-repo project overlay

Date: 2026-08-13

## Status

Accepted

Extends [36. MCP knowledge-graph memory with a private local store](0036-mcp-knowledge-graph-memory-with-a-private-local-store.md)
(the graph gains a cross-repo `project` entity — nothing in 0036 is
reversed) and carries forward the content contract from
[33. Memory is a pointer layer](0033-memory-is-a-pointer-layer-the-content-contract.md)
(pointer layer, never-cache-status — the clause ADR-0036 kept; 0033's
per-repo residency model is retired and not cited here).

Membership-enumeration, index-home, and probe-before-trust clauses amended 2026-08-23 by
[52. Dedicated member repos join a project wholesale](0052-dedicated-member-repos-join-a-project-wholesale-amending-the-adr-0040-membership-clause.md)
— dedicated member repos join a project wholesale, with the dedicated-repo list moving to a
committed manifest; the rest of this ADR is unchanged.

Ordering clause amended 2026-08-24 by
[53. Fully mechanical order and native-link-only membership](0053-fully-mechanical-order-and-native-link-only-membership-amending-the-adr-0040-ordering-and-enumeration-clauses.md)
— the priority-ladder tiebreak is fully mechanical (stable (repo, number)), retiring the
backlog-manager's judgment tiebreak; the rest of this ADR is unchanged.

Membership-enumeration clause further narrowed and corrected 2026-08-24 by
[53. Fully mechanical order and native-link-only membership](0053-fully-mechanical-order-and-native-link-only-membership-amending-the-adr-0040-ordering-and-enumeration-clauses.md)
— source (b) is checkbox-leading-token-only, source (c) is native-link-graph-only (no free-text
body scraping), and source (a)'s "same-repo" framing (below) is dropped — GitHub's sub-issues
feature is cross-repo and cross-org; the rest of this ADR is unchanged.

## Context

The backlog-manager operates per repo — GitHub Issues next to the code —
but a "project" is sometimes one repo and sometimes several: the agent
operating model (dotfiles#545) spans dotfiles, infra,
project-starter-template, and the agents repo (dotfiles#563). A
multi-repo project has no unified "what's next," so the backlog-manager
stitches N backlogs by hand, and the tooling question (Linear? GitHub
Projects? per-repo?) was re-litigated repeatedly. Settled 2026-08-13 via
grilling on dotfiles#566.

## Decision

**Per-repo GitHub Issues are the source-of-record, always.** Issues stay
next to the code they're about — one-home-per-fact, keeping per-repo CI,
labels, branch protection, and `blocked-by` links. A **project overlay**
switches on _only_ when work spans ≥2 repos.

- **Virtual, not a materialized board.** A `project` entity in the MCP
  memory graph records the anchor epic + member repos; the
  backlog-manager computes the cross-repo view on demand — query the
  mapped repos live, merge, never cache.
- **Priority single-homed.** Repo `priority:` labels stay authoritative
  for in-repo urgency; cross-repo sequencing rides native `blocked-by`
  links; nothing is stored at project level. The cross-repo order is a
  live derivation, re-run each grooming.
- **Membership via the anchor epic's native link graph.** A project is
  anchored by an epic (or tracking issue); its members are the issues
  reachable via native links. The graph `project` entity is the index
  (which repos to query) plus the project-level memory home — the
  cross-repo home ADR-0036's graph model allows but hadn't yet needed.
  ADR-0033's surviving contract applies at this level unchanged: the
  entity holds pointers, never issue status.
- **Single-repo projects get no overlay.** The repo _is_ the project.
  The trigger is mechanical: work crosses a second repo → create the
  `project` entity + anchor; below that, nothing.

Compute mechanics are pinned so the view is reproducible, not left to
judgment:

- **Membership enumeration** — from the anchor epic, collect members
  from three native sources: (a) GitHub sub-issues (same-repo; the
  `subIssues` GraphQL field — the CLI has no flat traversal); (b) the
  epic body's checkbox task-list references; (c) cross-repo
  `blocked-by`/`blocking` links and explicit `#`/URL references.
  Traversal is recursive — apply all three sources to each discovered
  issue until no new issue appears, with a visited set for dedup and
  cycles; "reachable" means the transitive closure, not the anchor's
  direct children. The stored member-repo list is only a probe-before-trust
  query scope; the live link graph is authoritative — a link reaching an
  unlisted repo wins and updates the hint.
- **Cross-repo `blocked-by` is native** — `gh issue edit
--add-blocked-by <url>` works across repos (confirmed infra#76 ↔
  dotfiles#377, routine token). No custom mechanism.
- **Priority is comparable by construction** — every managed repo
  carries the same canonical `priority: high/medium/low` set (infra's
  `repos.tf` applies one label set to all repos), so no normalization
  table. Cross-repo order = topological by `blocked-by`, then the shared
  priority ladder, then the backlog-manager's judgment tiebreak.

## Alternatives considered

- **Linear (or any external tool)** — moves the source-of-record off the
  code (breaks one-home-per-fact), forces rebuilding the `gh`-native
  backlog-manager, and sync integrations rot. Revisit only if a real
  team plus heavy cross-repo PM materializes.
- **Materialized-board-first (GitHub Projects v2)** — overhead (a board
  to maintain, the v2 GraphQL surface) before a proven need; virtual is
  reversible, a board isn't. Kept as a forward option the design must
  not preclude: if built, its fields are _derived_ from the same
  computation, never a competing authority.
- **Repo-granularity membership** — over-includes; a repo hosts issues
  for multiple projects.
- **A project-level priority field** — a second home for priority, which
  drifts against the repo label.

## Consequences

A multi-repo "what's next" becomes a defined computation instead of
hand-stitching, at the cost of recomputing it each grooming — accepted;
a cache would be a second home for status. Project indexing and
project-level memory ride the still-in-trial MCP graph (ADR-0036's
parallel run) — membership itself stays with the anchor epic's live
link graph, the entity only a query hint; if the trial
reverts, these one or two entities migrate with all memory — low,
accepted. First worked example: the `agent-operating-model-project`
entity, anchored on dotfiles#545.

Revisit if a materialized board is actually built (derive its fields
from this computation) or if cross-repo scale outgrows live enumeration.
