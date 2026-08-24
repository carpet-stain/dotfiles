# 53. Fully mechanical order and native-link-only membership, amending the ADR-0040 ordering and enumeration clauses

Date: 2026-08-24

## Status

Accepted

Amends [40. Per-repo backlog with a virtual multi-repo project overlay](0040-per-repo-backlog-with-a-virtual-multi-repo-project-overlay.md)'s
ordering clause (named, not line-cited — see [52](0052-dedicated-member-repos-join-a-project-wholesale-amending-the-adr-0040-membership-clause.md)
for why) and further narrows its membership-enumeration clause, on top of
[52. Dedicated member repos join a project wholesale](0052-dedicated-member-repos-join-a-project-wholesale-amending-the-adr-0040-membership-clause.md)'s
own narrowing (the dedicated-repo union). ADR-0040 stays Accepted — per-repo Issues as
source-of-record, the virtual overlay, live computation, single-homed priority, and native
`blocked-by` sequencing are untouched.

## Context

`carpet-stain/dotfiles#669` Phase 1 (`scripts/project-queue.mjs`, merged) is the first artifact
that actually _executes_ ADR-0040's "live computation" mechanically — a committed, tested script,
not a backlog-manager session re-deriving it by hand. Building it surfaced two gaps between
ADR-0040's original wording and what a mechanical implementation can actually do.

**The ordering clause ends in judgment a mechanical process can't hold.** ADR-0040's compute
mechanics say: "Cross-repo order = topological by `blocked-by`, then the shared priority ladder,
then the backlog-manager's judgment tiebreak." A committed script (or a materialized board's sync
job) has no session in which a human breaks a tie — it has to terminate in something deterministic
or the output isn't reproducible run to run. This also already contradicted ADR-0040's own earlier
line, "not left to judgment" — a self-contradiction the original ADR carried since 0040, not
something #669 introduced.

**The membership-enumeration clause was under-specified enough to over-include.** ADR-0040 named
three sources loosely: "(b) the epic body's checkbox task-list references" and "(c) cross-repo
`blocked-by`/`blocking` links and explicit `#`/URL references." Read literally, (c)'s "explicit
`#`/URL references" licenses scraping an epic's body prose for any `#N` mention — #669's own
plan-review (round 4, reaffirmed round 8) found this would pull `#545` (the anchor's own parent),
`infra#217`, and `infra#208` onto the board from nothing more than passing prose mentions, exactly
the "corrupt the board's whole purpose" failure a materialized board can't afford (a board that
looks complete but silently over-includes is worse than no board). (b) had the mirror problem: a
checkbox whose _body_ merely mentions an issue mid-sentence (e.g. "Board membership honours #668's
union rule…") isn't a membership declaration, but nothing in the original wording said so.

\#669 Phase 1 already ships narrowed rules — leading-token-only for (b), native-link-graph-only for
(c), a fully mechanical (repo, number) tiebreak — because the engine had to decide something to run
at all. This ADR is the record catching ADR-0040 up to what's already shipped, per
`docs/adr/README.md`'s amendment convention (state now, don't silently let code and ADR drift).

**Source (a)'s "same-repo" framing was already wrong the day ADR-0040 was written, not something
that changed after.** ADR-0040 (2026-08-13) describes source (a) as "GitHub sub-issues (same-repo;
the `subIssues` GraphQL field)." GitHub's sub-issues feature went cross-repo GA in April 2025 and
cross-_organization_ in September 2025 — both over a year before ADR-0040's own date — verified
against GitHub's changelog (`github.blog/changelog/2025-04-09-evolving-github-issues-and-projects`,
`.../2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more`) and confirmed
structurally: `AddSubIssueInput`'s `subIssueId`/`subIssueUrl` carry no repo constraint. The engine's
own code never assumed same-repo — `ghFetchIssue`'s `toRefs` resolves a sub-issue's owner/repo from
its URL like any other native ref — so no code bug follows from this, only a stale ADR claim, caught
by the maintainer while reviewing this PR rather than left to rot (dotfiles#669's own comment
thread).

## Decision

**1 — Ordering clause: retire the judgment tiebreak.** Cross-repo order is topological on native
`blocked-by` (strongly-connected components — i.e. a real cross-repo blocking cycle — broken
deterministically by (repo, number) and surfaced as a data-quality warning, never silently ordered
around), then the shared `priority:` ladder, then a stable (repo, number) tie. No third term is
left to judgment.

**2 — Membership-enumeration clause: narrow (b) and (c).**

- **(b) checkbox task-list references count only when the reference is the checkbox's leading
  token** — the first content after the `- [ ]` / `* [ ]` / `+ [ ]` marker (GFM allows all three
  unordered-list markers). A reference elsewhere in the checkbox's text doesn't count.
  - Accepted leading forms: a bare `#N` (resolves to the containing issue's own repo) and a full
    `owner/repo#N`.
  - **Explicit ruling on the three forms #669's round-8 review flagged as under-specified — none of
    them count as a leading reference:** a markdown-linked ref (`[#670](url)`), a bare issue URL as
    the leading token, and an emphasis- or emoji-prefixed ref (`**#670**`, `🚀 #670`). Reasoning
    under Alternatives.
- **(c) is native link graph only** — `blocked-by`/`blocking`, however expressed (a bare `#N` or a
  full URL, since a URL is how `gh issue edit --add-blocked-by <url>` records a cross-repo link).
  ADR-0040's original "explicit `#`/URL references" wording is retired: a reference reaches
  membership only through a checkbox leading token (b) or a native link (c) — free-text body
  scraping never happens under either source.

**3 — Source (a)'s "same-repo" claim is corrected, and (b)'s role is named for what it actually is
now.** Source (a) is cross-repo and cross-org, full stop — drop "(same-repo; ...)" from ADR-0040's
membership-enumeration clause. This doesn't change the engine's behavior (it never enforced
same-repo), only the ADR's accuracy.

The corrected (a) also changes what (b) is _for_. When ADR-0040 was drafted, a checkbox leading-ref
was arguably the only way to declare a cross-repo membership at all — sub-issues supposedly
couldn't. That was never true (see Context), but now that it's _visibly, GA_-untrue, an epic author
has a native, UI-visible path (GitHub's own "Add sub-issue" picker) for the exact thing (b) was
built to approximate in body text. (b) isn't removed here — it still has to parse #669's own
pre-native-sub-issues history correctly (this ADR's own reconstructed fixture, `project-queue.test.mjs`),
and nothing stops an author from writing a checkbox instead of using the picker — but its role is now
backward-compatibility and author-preference, not the primary cross-repo membership mechanism (a)
was once mistakenly thought not to cover.

## Alternatives considered

- **Keep the judgment tiebreak.** Rejected — a script or sync job has no session in which to apply
  it, so keeping it in the ADR while every implementation mechanizes past it just lets the document
  drift from reality. It also self-contradicts ADR-0040's own "not left to judgment" line.
- **Accept markdown-linked / bare-URL / emphasis-emoji-prefixed leading refs.** Rejected for
  simplicity: two unambiguous, trivially machine-parseable forms (`#N`, `owner/repo#N`) cover every
  real case seen in practice (#669's own body), and parsing markdown link syntax or emoji Unicode
  ranges buys nothing an author can't get by writing the plain form. Revisit if this causes real
  friction — someone writing a markdown-linked checkbox and being surprised it doesn't count.
- **Body-wide free-text scraping for source (c)** (the original literal reading of "explicit
  `#`/URL references"). Rejected — #669's round-4 plan-review demonstrated concretely that it pulls
  unrelated issues onto the board from mere prose mentions, which is worse than the board not
  existing.
- **Deprecate or remove source (b) now that (a) covers cross-repo natively.** Rejected — #669's own
  body used checkbox-style membership declarations before this ADR's own fixture reconstructed that
  history, so (b) is load-bearing for anything written that way, past or future-by-preference.
  Removing working, already-shipped, tested parsing on a hunch about future authoring habits isn't
  justified by "there's now a better way" alone. Revisit if checkbox-declared membership turns out
  to be rare/unused in practice once sub-issues are the visible default.

## Consequences

- `Ready` ordering computed by any tool consuming this ADR (`project-queue.mjs`, a future
  board-sync) is byte-reproducible from the same inputs — no session-to-session drift from a human
  tiebreak, and no board reader has to wonder why two same-priority items swapped position between
  syncs.
- A checkbox author who wants an issue counted must lead with a plain `#N` or `owner/repo#N` — a
  markdown-linked or emphasized reference silently does _not_ count. Not flagged anywhere an author
  would see it while typing; worth a callout (e.g. an epic issue-template hint) if this trips people
  up in practice, not built here.
- ADR-0040 keeps its narrative shape unchanged; it gains two more dated marker lines under its
  Status (one per clause this ADR amends), alongside the existing ADR-0052 marker — three markers
  total, per `docs/adr/README.md`'s "clause → dated marker" convention applied per-clause, not
  per-ADR.
- ADR-0040's membership-enumeration clause no longer misdescribes source (a) as same-repo — a
  future reader who checks whether a cross-repo sub-issue is supported gets the right answer from
  the ADR itself, not just from reading the engine's code.

Revisit if a real need for markdown-linked/URL/emphasis leading refs shows up, if cycle-breaking
ever needs richer diagnostics than a single forced (repo, number) pick, or if checkbox-declared
membership (source b) turns out to be rare enough in practice to simplify away now that sub-issues
are the visible native path.
