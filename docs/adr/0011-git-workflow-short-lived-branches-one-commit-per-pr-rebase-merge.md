# 11. Git workflow: short-lived branches, one commit per PR, rebase-merge

Date: 2026-07-11

## Status

Accepted

## Context

PRs accumulated multiple commits before merge. Squash-merge cleaned up the final
result on `main`, but nothing required a PR to actually be atomic — `AGENTS.md`
said "scope each commit to one logical change" without enforcing that a PR _is_
one commit (#76). Work happened on a long-lived `dev` branch where committing
"freely and messily" was explicitly sanctioned, and PRs tracked shared `dev`
rather than short-lived feature branches (#76). Under squash-merge, GitHub made
the PR title the commit message on `main`; `pr-title.yml`'s own header stated
`release-publish.yml` keyed off that format, so `pr-title.yml` validated the
title, not the commit (pr-title.yml).

Grooming reframed the goal: not "let squash-merge collapse WIP for me" but one
change, one commit, one PR, with the author owning the commit and its message —
squash-merge explicitly not relied upon (#76). That reframe forced a
merge-method change: owning the final commit is incompatible with squash-merge
rewriting it.

## Decision

Short-lived feature branches off protected `main`. Commit freely on the branch;
when ready, squash to exactly one Conventional Commit, then rebase-merge so that
commit lands on `main` verbatim (#76, fffa8fa8). `pr-guards.yml` gates every PR
on two required checks — exactly one commit, and a Conventional Commit subject —
and repo merge settings allow rebase-merge only (#76, fffa8fa8).

## Alternatives considered

- **Squash-merge (the prior model)** — squashing to one commit yourself but
  leaving squash-merge on means GitHub re-squashes it and overwrites your
  hand-written message with the PR title, so the author can't own the commit
  that lands on `main` (#76). Validating the PR title (`pr-title.yml`) was then
  checking the wrong artifact — the title, not the commit that merges
  (pr-title.yml).
- **Long-lived `dev` working branch** — PRs tracking shared `dev` had no signal
  distinguishing a WIP push from a PR-ready state, so one-commit-per-PR couldn't
  be enforced without breaking the sanctioned free/messy `dev` commits (#76).
  Retired along with `sync-dev.yml` and the pre-push rebase hook (fffa8fa8).
- **Merge commits** — disabled at the repo level alongside squash-merge, leaving
  rebase-merge only (#76, fffa8fa8).
- **A pre-commit / pre-push git hook to enforce one-commit-per-PR** — locally
  there's no signal telling a WIP `dev` push apart from a PR-ready state, so a
  hook can't enforce it without blocking free WIP commits; the fitting local
  mirror is a `git pr` / PR-creation-time guard, not a hook (#76, fffa8fa8).

## Consequences

The author owns the exact commit on `main` — its message survives verbatim, and
git-cliff reads that subject for the changelog, so the Conventional Commit gate
is load-bearing (pr-guards.yml). rebase-merge is only safe because the
single-commit gate holds; a multi-commit PR would otherwise replay several
commits onto `main` (#76). Squash-merge and merge-commit are disabled at the
repo level, and required status checks point at the two `pr-guards.yml` jobs —
both changed out-of-band via the admin session the scoped PAT can't reach (#76,
fffa8fa8). Retired: `pr-title.yml`, `sync-dev.yml`, the pre-push rebase hook,
and the `dev` branch (fffa8fa8). Cost: every PR must be squashed before merge —
a mandatory step, mirrored locally by the `git pr` guard rather than left to CI
alone (#76, fffa8fa8, git/config). Revisit if git-cliff stops reading the landed
commit's subject for the changelog, or if a future need for multi-commit history
on `main` outweighs author-owned atomic commits (inferred).
