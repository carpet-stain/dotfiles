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

## Early draft PRs — `git pr` / `git pr --draft`

Realizes `git.md`'s "open the PR/MR early, journal via comments" principle on GitHub: `git pr
--draft` opens a draft PR as soon as a first commit exists (errors loudly instead of guessing if
one already exists — "did you mean to finalize? run: git pr"); plain `git pr` either opens the
finalized PR directly (no draft existed yet) or finalizes an already-open one via `gh pr ready`.
Each path asserts its own precondition — commit count ahead of the base — and fails with a
specific message rather than branching on ambient state. Journal decisions, gotchas, and
retractions as comments on the draft PR as work proceeds.

`pr-guards.yml` (see its own inline comments for the exact gate) stays quiet on WIP pushes to an
early draft and evaluates for real once `git pr` finalizes it — gated per job, not
workflow-level, because a job skipped via a job-level `if:` reads as passing to
required-status-check branch protection, not failing (verified empirically against this repo's
branch protection, not assumed from docs), while a workflow-level `if:` that skips the whole run
is the sharp edge that can hang a required check instead.

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
