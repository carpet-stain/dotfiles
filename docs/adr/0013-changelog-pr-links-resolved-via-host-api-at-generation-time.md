# 13. Changelog PR links resolved via host API at generation time

Date: 2026-07-12

## Status

Accepted

## Context

Every commit's changelog PR link `(#N)` used to come from squash-merge
auto-appending it to the subject, which `cliff.toml`'s `commit_preprocessors`
regex turned into a link. #107 switched `main` from squash-merge to rebase-merge
so the author's commit lands verbatim, but rebase-merge rewrites the SHA and
never appends `(#N)` — so every commit merged since had no PR reference anywhere
in its message (8169995e). #121 patched this by making `git-pr-link.sh` amend
the squashed commit's subject to append `" (#N)"` and force-push before merge —
faking the text squash-merge used to add (8169995e).

The #125 spike then verified two things rather than assuming them: git-cliff
resolves each commit's PR natively via GitHub's API (`[remote.github]`,
`commit.remote.pr_number`), and that server-side commit-to-PR association
survives rebase-merge's SHA rewrite (the `/commits/{sha}/pulls` endpoint exists
precisely because rebase-merge broke message-based inference). That makes the
amend-and-force-push hack unnecessary and removes its fragility (bf8d0d44).

## Decision

Resolve `(#N)` changelog links from GitHub's own commit-to-PR association at
changelog-generation time, not by encoding `(#N)` into commit messages.
`cliff.toml` uses `[remote.github]` (`owner`, `repo`) plus a `body` template
referencing `commit.remote.pr_number`; `commit_preprocessors` now strips any
legacy `(#N)` text instead of linking it, so historical entries don't get a
duplicate link (bf8d0d44, cliff.toml). `GITHUB_TOKEN` is aliased to the scoped
`GH_TOKEN` in `.envrc` locally and wired into both release workflows (bf8d0d44).
`git-pr-link.sh`'s amend-and-force-push step is dropped; finalize becomes just
`gh pr ready` (#125 spike outcome).

## Alternatives considered

- **In-commit-text `(#N)` amend-and-force-push (#121's interim fix)** —
  superseded. It faked the text squash-merge used to auto-append, but a
  pre-merge text convention can't survive rebase-merge's SHA rewrite reliably,
  and the amend-then-force-push before every merge is fragile (bf8d0d44 message,
  #125 spike outcome).
- **Keeping the `commit_preprocessors` regex on `(#N)` text** — the prior
  mechanism, rejected. It only works if the text is already in the message,
  which nothing produced once squash-merge was retired; the GitHub-remote lookup
  resolves the PR regardless of what the subject says (#125 spike outcome,
  cliff.toml comment).

## Consequences

Finalizing a PR no longer rewrites the squashed commit or force-pushes just to
add a link — the commit lands on `main` verbatim, and links resolve at
generation time (bf8d0d44). Commits merged in the gap between rebase-merge
adoption (#107) and the #121 amend fix — which never carried any `(#N)` text —
now resolve too (bf8d0d44).

Costs: `git cliff` is network-dependent by default and needs a token
(unauthenticated GitHub API is 60 req/hr); local preview (`git cliff --bump`)
loses its pure-offline property unless `--offline`/`GIT_CLIFF_OFFLINE` is set
(#139). The repo's oldest 7 PRs lose their link on the next full regen — their
on-main SHA doesn't match GitHub's merge record (an old history rewrite
unrelated to rebase-merge), accepted as the smallest cost given everything else
is as good or better (bf8d0d44).

Enforced now by `cliff.toml`'s `[remote.github]` block and the stripping
`commit_preprocessors`; codified host-neutrally in `claude/rules/tools/git.md`
and concretely in `claude/rules/platform/github.md` (#139). Revisit if
git-cliff's GitHub-remote support changes, if the repo becomes a monorepo
(git-cliff #880: 404s fetching PR details), or if rate limits stop supporting a
full-history regeneration (#139).
