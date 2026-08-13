# 38. Agent authors, maintainer ships, amending the ADR-0035 shipped-work clause

Date: 2026-08-13

## Status

Accepted

Amends ADR-0035's shipped-work clause only; ADR-0035 stays Accepted.

## Context

ADR-0035 splits agent-facing content by ownership. Its shipped-work clause reads: "Commits,
PRs, and code stay under the maintainer's identity; `voice.md` narrows to him and
implementation content." This ADR amends only that clause — the named-identities decision for
deliberation stands untouched.

The one-day-old reasoning changed on the authorship-vs-ownership split. The clause conflated
two facts a commit records: who owns and ships the work (the maintainer — he directs, reviews,
pushes, merges) and who mechanically wrote the lines (the agent). Attributing the author field
to the maintainer makes `git blame` name a human for machine-written lines — dishonest blame,
the same identity laundering ADR-0037 removed from prose, one layer down, and it destroys the
audit trail the agent design rests on (#544).

What made it concrete: infra#174 provisioned the implementor machine-user account
(`carpet-stain-implementor`, numeric ID 316583991 — the planned `implementor` login was
already taken on github.com), and GitHub links a commit to an account purely by author email,
independent of who pushes.

## Decision

Agent authors, maintainer ships:

- **Git author = the implementor identity** —
  `carpet-stain-implementor <316583991+carpet-stain-implementor@users.noreply.github.com>`,
  set via `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` in the `/implement-issue` runtime. The noreply
  form links to the account by construction; the author field survives rebase-merge verbatim
  (ADR-0016's provenance chain), so blame stays honest on `main`.
- **Committer = merger = maintainer.** Rebase-merge rewrites the committer to whoever merges —
  accepted as the honest "who shipped it" and the accountability anchor (committer plus the
  PR's `merged_by`).
- **No write credential.** The author field is independent of the push token, so push and
  merge stay the maintainer's; the agent gets no write grant. The safety property comes free:
  the human is the only actor who can push or merge.
- **Graph-level machine-vs-human separation is a non-goal.** The real metric builds off the
  author field plus provenance trailers in the observability track (#545), not GitHub's
  contribution graph.

Ownership is unchanged: the work still ships as the maintainer's, and `voice.md` still governs
how it sounds — author is mechanical blame, voice is the owner's narrative; the two are
orthogonal.

## Alternatives considered

- **Keep the maintainer as author** — preserves ADR-0035's clause but leaves blame naming a
  human for machine-written lines; rejected as the dishonesty this arc exists to remove.
- **Supersede ADR-0035** — wrong relation, same as ADR-0037: the named-identities decision is
  live and in-build (#540); a clause amendment keeps it standing.
- **`Co-authored-by` trailer instead of the author field** — a trailer is a credit line, not
  blame; `git blame` still names the maintainer, and GitHub's co-author rendering is
  cosmetic. The author field is the mechanical record.
- **Agent pushes under its own credential** — gives honest authorship plus credential
  isolation, but mints a standing write grant for no authorship gain (author is independent of
  the push token). Deferred to infra#174's deferred section, taken up only on a concrete
  threat and only after a ruleset spike proves push-not-merge is expressible.

## Consequences

`git blame` on agent-written lines resolves to a clickable `carpet-stain-implementor` team
identity; the maintainer remains the only actor who can push or merge. The committer field and
`merged_by` carry his accountability. Costs: one more machine account to hold (no credential
on it yet), and tooling that inspects authorship (changelog, metrics) now sees two authors —
the observability track (#545) builds on exactly that. Revisit the write-credential deferral
only on a concrete threat, per infra#174.
