# 4. git-cliff for changelog generation and version computation

Date: 2026-07-04

## Status

Accepted

## Context

The repo commits to Conventional Commits and SemVer, and `main` stays releasable
(#3). Before git-cliff, releases were cut with
`gh release create vX.Y.Z --generate-notes`, which bullets every PR merged since
the previous tag — notes tied to GitHub's PR list, with no committed changelog
and no derivation from the commit types the repo already enforces (7da2cf9e
AGENTS.md diff). Epic #3 tracked release automation with git-cliff as the
remaining piece, explicitly gated on "once history is consistently Conventional"
(#3). By 2026-07-04 that precondition held, so a tool was needed to turn the
Conventional-Commit history into a durable, in-repo `CHANGELOG.md` and drive
release notes from the same source instead of GitHub's PR-list generator.
Adopted in #16 (7da2cf9e).

## Decision

Adopt git-cliff to build `CHANGELOG.md` from the Conventional-Commit history,
configured by a committed `cliff.toml`; installed via Homebrew
(`macos/Brewfile`). Release flow (as documented at #16): generate
`git cliff --tag vX.Y.Z -o CHANGELOG.md`, commit as `chore(release): vX.Y.Z`,
tag, then publish notes from the same source
(`gh release create vX.Y.Z --notes-file <(git cliff --tag vX.Y.Z --latest --strip all)`).
`cliff.toml`'s `commit_parsers` map each Conventional type to a changelog group;
`chore(release)`/`chore(deps)` and non-conventional commits are skipped
(7da2cf9e cliff.toml).

## Alternatives considered

- **`gh release create --generate-notes`** (the prior flow) — bullets merged PRs
  from GitHub's API rather than deriving anything from Conventional-Commit
  types, and leaves no committed `CHANGELOG.md` in the repo; git-cliff makes the
  enforced commit convention the single source for both the changelog and the
  release notes (7da2cf9e AGENTS.md diff).
- **Hand-maintained `CHANGELOG.md`** — (inferred) defeats the point of enforcing
  Conventional Commits; a generated changelog needs no manual upkeep and can't
  drift from history. No source names this alternative.

## Consequences

One source — the Conventional-Commit history — now feeds both `CHANGELOG.md` and
GitHub release notes, and the changelog lives in the repo (7da2cf9e).
`cliff.toml` is the enforced spec: adding a commit group or changing what's
skipped is a reviewable diff, not tool flags. Depends on history staying
consistently Conventional (#3); non-conventional commits are silently dropped.
git-cliff must be installed (`git-cliff` in `macos/Brewfile`) to cut a release.
This decision covers changelog generation only; automated SemVer bump
computation (`git cliff --bump`, `bump=auto`) came later and was not part of #16
(5c58e899, #103), and resolving PR links via GitHub's API at generation time is
a separate decision (see ADR 0013, #139). Revisit if the repo drops Conventional
Commits or SemVer, or moves off GitHub for release publishing.

(provenance: partial — the hand-maintained-CHANGELOG alternative is inferred,
named by no source.)
