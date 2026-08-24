# 52. Dedicated member repos join a project wholesale, amending the ADR-0040 membership clause

Date: 2026-08-23

## Status

Accepted

Amends [40. Per-repo backlog with a virtual multi-repo project overlay](0040-per-repo-backlog-with-a-virtual-multi-repo-project-overlay.md)'s
membership-enumeration, index-home, and probe-before-trust clauses (named, not line-cited — a
line-number citation to a sibling ADR drifts the moment either file is edited, exactly what this
ADR's own Status marker in ADR-0040 avoids).
ADR-0040 stays Accepted — per-repo Issues as source-of-record, the virtual overlay, live
computation, single-homed priority, and native `blocked-by` sequencing are untouched. Extends
[47. Epic completion automation stays same-repo behind a cross-repo guard](0047-epic-completion-automation-stays-same-repo-behind-a-cross-repo-guard.md)
(Decision 2's superset precondition — this ADR adds a membership source, so the guard must widen;
tracked, not yet built — see Consequences).

## Context

The 2026-08-22 live traversal of dotfiles#545 found most of agent-memory-server's open issues
invisible to the project view. ADR-0040 defines membership as the anchor epic's native link graph
(sub-issues, task-list refs, cross-repo `blocked-by`/references). agent-memory-server exists
solely to serve #545, but its issues don't link upward, so the rule excludes them by construction.
The rule is literally correct and practically wrong: work started inside a member repo doesn't
join the project unless someone remembers to link it upward, and in practice nobody does. This
gets worse once a materialized board (dotfiles#669) lands — a board that silently omits most of a
member repo's backlog is more misleading than no board, because it gets trusted at a glance.

The original filing cited agent-memory-server#17 (`priority: high`) as the headline example; it
has since closed. The live invisible set at decision time was 6 open issues topping out at
`priority: medium`. The structural argument is unchanged — the urgency example is just spent.

## Decision

**Membership = the anchor's link graph ∪ every issue in the project's dedicated member repos.**

This is ADR-0040's own rejected "repo-granularity membership" alternative ("over-includes — a repo
hosts issues for multiple projects"), narrowed by a predicate that defuses exactly that objection:
a **dedicated member repo** exists solely to serve one project. Where ADR-0040 rejected
repo-granularity _everywhere_, this ADR re-accepts it _only_ where a repo has no second project to
be over-included from.

- A **dedicated member repo** — agent-memory-server today — has every one of its issues join its
  project by default, no upward link required.
- **Shared repos stay link-graph.** dotfiles and infra host issues for many projects; ADR-0040's
  repo-granularity rejection stands for them unchanged.
- A repo qualifies as dedicated only if it serves exactly one project. The day a dedicated repo
  starts hosting a second project's issues, it reverts to link-graph and its manifest entry (below)
  comes out — this is a manifest edit, not automatic, gated the same as any other manifest change.

### Where the dedicated-repo list lives

**A committed, anchor-keyed manifest in dotfiles** (`project-manifest.yaml`) — `anchor → [dedicated
repos]` — read by both the backlog-manager and #669's sync workflow. The memory graph's `project`
entity holds a **pointer only**.

This reverses the original proposal (graph entity as authoritative). The reason is structural, not
a credential gap: ADR-0046 makes memory per-role and lane-scoped with no cross-role reads, so a CI
workflow must not read the backlog-manager's private store even if handed a credential. Role-private
memory cannot be a shared config source. A flat repo list is insufficient too — at a second project
it would re-create the cross-project over-inclusion ADR-0040 rejected, hence anchor-keying.

- **Schema:** `projects: [{anchor: "<repo>#<number>", dedicated_repos: ["<repo>", ...]}]`. Anchor
  is `repo#number` (repo short name, matching `scripts/work-queue.sh`'s `REPOS` naming); dedicated
  repos are short names from the same set. Validated in CI (`scripts/check-project-manifest.sh`,
  wired into `lefthook.yml`): parses, anchors match the `repo#number` shape, no duplicate anchors,
  no empty `dedicated_repos` list.
- **Live-repo liveness (renamed/archived target) is out of the schema validator's scope** — it's a
  runtime concern for whatever reads the manifest (#669's sync), which reports and skips that repo
  rather than failing the whole run, matching #669's fail-closed posture. The validator here only
  guards structural shape at commit time.
- **Approval path:** a manifest edit wholesale-imports a repo's entire backlog, so it takes
  human/backlog-manager sign-off, not a schema check alone — the schema check catches malformed
  entries, not bad judgment calls about what's dedicated.
- **Anchor re-keying:** a successor epic means a manifest edit, gated by the same sign-off — the
  right moment to re-confirm the dedicated list. Not automatic.

### Clauses reversed (ADR-0040)

1. **Membership enumeration** ("Membership via the anchor epic's native link graph") — gains the
   union with dedicated-repo members.
2. **Index-home** ("the graph `project` entity is the index") — moves to the manifest. This moves
   partially for _any_ project with a dedicated member, not only for the dedicated repos
   themselves — the manifest becomes part of the index for every such project.
3. **Probe-before-trust** ("the stored member-repo list is only a probe-before-trust query scope;
   the live link graph is authoritative") — for the dedicated list specifically, the manifest is
   authoritative, since the link graph structurally cannot express "all of this repo." The
   member-repo _hint_ for link-graph traversal keeps its probe-before-trust status unchanged.

**Amend, not supersede.** ADR-0040's core survives: per-repo Issues as source-of-record, virtual
overlay at ≥2 repos, live computation, priority single-homed in repo labels, cross-repo sequencing
on native `blocked-by`. ADR-0046 is precedent for one ADR amending clauses of two others (here:
ADR-0040 and ADR-0047).

### ADR-0047 extension — deferred code obligation

ADR-0047 Decision 2 binds: "the guard's signal set is a superset of ADR-0040's cross-repo
membership sources; if 0040 ever gains a membership source, the guard widens first." This ADR adds
one, and dedicated-repo members emit **no anchor-side signal** by design — so the `epic-complete`
nudge (dotfiles#592) could false-close an epic whose only open work sits in its dedicated repo.

**Widening: a project with a dedicated member repo holding open issues is a skip signal.** Shape
difference, recorded so a future reader doesn't flatten it: ADR-0047's existing guard is
signal-present (open-agnostic — a multi-repo epic with any cross-repo signal never auto-closes,
falling to the grooming sweep instead); this widening is signal-present-**and**-open (skips only
while the dedicated repo has open issues). Collapsing the two into one open-agnostic check would
mean a multi-repo epic with a dedicated member never auto-closes.

**The code lives elsewhere and is deferred.** The predicate is in
`carpet-stain/project-starter-template`'s `reusable-epic-complete.yml@v1`; dotfiles'
`epic-complete.yml` is a thin caller. Tracked in
[project-starter-template#132](https://github.com/carpet-stain/project-starter-template/issues/132).
Interim coverage, verified 2026-08-23: the only dedicated anchor (#545) already carries other
cross-repo signals (`infra#174`, `agents#22`), so today's guard already skips it and no epic is at
risk. Exposure opens the day a manifest entry appears whose anchor carries no cross-repo signal
other than its dedicated repo.

### Drift detection, and what it can't catch

The grooming sweep (not #669's sync workflow — ADR-0047 rejected CI maintaining a second
membership implementation, and "is this repo still dedicated?" is a judgment call, not something a
schema validator can decide) flags a dedicated repo containing an issue whose link graph points at
an anchor the manifest doesn't claim — the machine-readable signal that a repo has stopped being
dedicated.

**Stated accepted gap:** that detector cannot fire on over-inclusion. An over-included issue links
to _no_ anchor, which is exactly why wholesale membership sweeps it in. Unrelated junk accumulating
in a dedicated repo silently joins the view. The real gate is declaration discipline at
manifest-edit time — this is a known limitation, not a solved problem.

## Alternatives considered

- **Keep strict link-graph, link harder.** Depends on remembering, every time, forever. The
  2026-08-22 traversal is the evidence it fails in practice.
- **One agent-memory-server tracking epic, linked once to #545.** The existing link graph would
  then pull it in with no new rule at all — verified never tried: #545's body contains zero
  references to agent-memory-server. Rejected on **per-repo-once vs per-issue-perpetual**: a
  tracking epic needs every new issue re-linked and is incomplete by omission; the manifest
  registers the repo once and includes subsequent issues automatically. Not rejected for "being an
  obligation" — that argument would indict ADR-0040's own link discipline just as much.
- **Repo-granularity everywhere.** Already rejected by ADR-0040 — over-includes, since a repo can
  host issues for multiple projects. Unchanged for shared repos; the dedicated case is precisely
  where that objection doesn't apply.
- **A `project:` label per issue.** A second home for membership that drifts against the link
  graph, and infra's labels are OpenTofu-governed.
- **Graph entity as the authoritative home** (the original proposal). Rejected: violates
  ADR-0046's no-cross-role-reads, leaving #669's workflow unable to read it.

## Consequences

- Dedicated repos need no upward links — the whole point of this ADR.
- Adding a repo to a project now has two mechanical triggers: work crosses a second repo (create
  the `project` entity + anchor, per ADR-0040) or a repo is dedicated (record it in the manifest).
- The manifest is a new artifact and a known asymmetry: cross-repo governance config living in one
  member repo (dotfiles), accepted because dotfiles already hosts ADR-0040 and the agent config.
- ADR-0047's guard widening (project-starter-template#132) is deferred, tracked, and safe today
  only because the one live dedicated anchor (#545) has other cross-repo signals. Revisit the
  urgency of #132 the day a second dedicated anchor is added whose only cross-repo signal is its
  dedicated repo.
- The drift detector catches "stopped being dedicated" but not over-inclusion of unrelated issues
  in a dedicated repo — an accepted, stated gap, not a solved one.
- Cross-repo submodule drift (the `carpet-stain/agents` `backlog-manager.md` change landing without
  the dotfiles submodule bump that picks it up) is unenforced — accepted risk, not solved. No
  automated check exists for it.

Revisit if a dedicated repo starts serving a second project, if the manifest outgrows a flat
per-anchor list, or if project-starter-template#132 lands and the shape-difference note above needs
updating to match the shipped predicate.
