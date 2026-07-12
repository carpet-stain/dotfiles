<!-- GitHub platform mechanics. Canonical source: my dotfiles. Platform-level only: gh CLI,
     GitHub Actions, and GitHub's specific behaviors of the generic git workflow (git.md).
     Wrong for non-GitHub repos. Assumes git.md's workflow is in effect.
     Rationale: claude/README.md. -->

> ### GATE
>
> Applies only if this repo's origin is GitHub (remote points at github.com, or gh is configured
> for it). Otherwise IGNORE this file — don't apply gh/PR mechanics to a GitLab or other repo.

> ### LOCAL-WINS
>
> If this repo has its own GitHub-specific workflow doc, that doc is AUTHORITATIVE: treat this as
> baseline and prefer the repo's doc on conflict.

# GitHub Mechanics

Realizes `git.md`'s workflow on GitHub. No placeholders — `git.md` owns everything composable.

## Rebase-merge and branch protection

GitHub rebase-merge replays the branch's commits onto the protected branch as-is — it doesn't
rewrite the message the way squash-merge does, so the commit itself (already squashed to one,
already a Conventional Commit subject) is what lands, not the PR title. Branch protection
(rules/rulesets) is what enforces `git.md`'s single-commit + rebase-merge rule and required status
checks. "PR" is GitHub's review/merge request.

## Local tooling

`gh` defaults to a scoped-down fine-grained PAT (contents/PRs/actions read-write, no
Administration), not a full `gh auth login` session, so routine work can't touch repo settings or
branch protection — elevate explicitly (`env -u GH_TOKEN gh ...`) only for the one action that
needs admin. `act` runs the Actions workflows locally via Docker, for testing without pushing.

## Releases — gh

Publish notes from the same git-cliff source as `git.md`'s Releases:
`gh release create <TAG> --notes-file <(git cliff --tag <TAG> --latest --strip all)`.

## Changelog PR links — git-cliff GitHub remote

Realizes `git.md`'s "resolve PR links via the host's API" principle on GitHub: `cliff.toml`'s
`[git]` section sets `commit_preprocessors` to strip any legacy "(#N)" text instead of linking it,
and a `[remote.github]` section (`owner`, `repo`) plus a template using `commit.remote.pr_number`
resolve the link at generation time. Never put a token in `[remote.github]`'s `token` field — pass
it via the `GITHUB_TOKEN` env var (or `--github-token`) at invocation time instead, same as any
other secret. `git-cliff` specifically wants `GITHUB_TOKEN`, not `gh`'s `GH_TOKEN` — alias it to
whatever scoped token this repo's credential setup already provides (`git.md`'s credential-scoping
principle) rather than introducing a second one. In CI, wire `GITHUB_TOKEN` (the default token, or
the release credential already in scope) into every workflow step that invokes `git cliff`.
Unauthenticated GitHub API is 60 req/hr — a token raises that to a workable ceiling for a
full-history regeneration.
