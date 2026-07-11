<!-- GitHub platform mechanics. Canonical source: my dotfiles.
     Platform-level only: gh CLI, GitHub Actions, and GitHub's specific behaviors of the
     generic git workflow (git.md). Wrong for non-GitHub (e.g. GitLab) repos —
     this file assumes git.md's workflow is already in effect and only adds what's
     specific to this one host. -->

> ### GATE
> Applies only if this repo's origin is GitHub (git remote points at github.com, or gh CLI
> is configured for it). Otherwise IGNORE this entire file — do NOT apply gh/PR mechanics to
> a GitLab or other non-GitHub repo; use that platform's own file instead.

> ### LOCAL-WINS
> If this repo has its own contributing/workflow doc that specifies GitHub-specific rules,
> that doc is AUTHORITATIVE: treat this as baseline and prefer the repo's doc on conflict.

# GitHub Mechanics

Realizes `git.md`'s generic workflow on GitHub specifically. No repo-specific placeholders
here — nothing in this file needs composing into a repo doc; `git.md` already owns that.

## Terminology

"PR" (used throughout `git.md`) is GitHub's term for a review/merge request. Branch protection
here means GitHub's branch-protection rules / rulesets, the mechanism that enforces `git.md`'s
squash-only merge method and required status checks.

## Squash-merge behavior

On GitHub, squash-merge carries the PR title into the resulting commit message on the protected
branch — title the PR as a Conventional Commit (`type(scope): subject`), per `git.md`.

## Local tooling

Concrete instance of `git.md`'s credential-scoping principle: `gh` CLI defaults to a scoped-down
fine-grained PAT (repo contents/PRs/actions read-write, no Administration) rather than a full
`gh auth login` session, so routine work can't touch repo settings or branch protection. Elevate
explicitly (e.g. `env -u GH_TOKEN gh ...`) only for the one action that needs full admin.

`act` runs the GitHub Actions workflows themselves locally (via Docker) — for testing workflow
changes without pushing and waiting on real CI.

## Releases — gh

Publish notes from the same git-cliff source `git.md`'s Releases section used to build
`CHANGELOG.md`:

```
gh release create <TAG> --notes-file <(git cliff --tag <TAG> --latest --strip all)
```

## Before Finishing, Ask

- Is the PR titled as a Conventional Commit, since GitHub carries it into the squash-merge commit?
- Is the `gh` session scoped down for routine work, full-admin only when the task actually needs it?
