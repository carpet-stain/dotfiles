<!-- LAYER 2 — GitHub platform mechanics. Canonical source: my dotfiles.
     Platform-level only: the gh/Conventional-Commits/git-cliff workflow, NOT any one
     repo's scopes, version scheme, or branch names — those fill the <placeholders>
     and live in each repo's own guide. Wrong for non-GitHub (e.g. GitLab) repos. -->

> ### APPLY GUARD
> APPLY ONLY IF this repo's origin is GitHub (git remote points at github.com, or gh CLI
> is configured for it).
> Otherwise IGNORE this entire file. Do NOT apply gh/PR mechanics to a GitLab or other
> non-GitHub repo — use that platform's own flow instead.
> If this repo has its own contributing/workflow doc that specifies commit or PR rules,
> that doc is AUTHORITATIVE: treat this layer as baseline and prefer the repo's doc on conflict.

> ### COMPOSE PROTOCOL (how to give a repo its own concrete GitHub workflow doc)
> Trigger: only when the human asks to scaffold, OR a GitHub repo lacks a stated commit/PR
> workflow and one is warranted. Default to PROPOSE, don't create — suggest and wait before
> writing committed files.
> Steps:
>   1. Read this layer once as the baseline.
>   2. Write a repo-local doc (or an AGENTS.md section) that fills the <placeholders> with
>      this repo's real values: <scopes> (its module/area names), <version-scheme>, the
>      <long-lived-branch>/<protected-branch> names, and whether release automation applies.
>   3. Wire the gate so local wins: add to the repo's committed AGENTS.md:
>        "This repo's workflow doc is authoritative for commit/PR rules; treat any generic
>         GitHub layer as baseline and prefer this repo's doc on conflict."
>      (Names NO personal path — commit-safe, true for any contributor.)
>   4. After this, the repo reads its own doc; do not re-distill this layer for that repo.

# GitHub Workflow

Mechanics for realizing my version-control discipline on GitHub. Repo-specific values
(commit scopes, version scheme, branch names) fill the <placeholders> and live in the repo.

## Commits — Conventional Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Every commit:

- **Subject** `type(scope): description`
  - `type` ∈ feat, fix, docs, style, refactor, perf, test, build, ci, chore
  - `scope` (optional): a repo area from this repo's <scopes>
  - `description`: imperative, lowercase, no trailing period; ≤50 chars where possible
    (hard limit 72)
  - Breaking change: `type!:` or a `BREAKING CHANGE:` footer
- **Blank line**, then a **body** wrapped at 72 chars explaining *what* and *why*, never
  *how* (the diff shows how). Omit only for trivial, self-evident changes.
- **Trailers** (optional): `Co-authored-by: Name <email>` per human contributor. Do NOT add
  AI/assistant attribution.

Scope each commit to one logical change — prefer several focused commits over one sweeping
commit. Propose the split and messages before committing.

## Branch & PR model — long-lived working branch + protected main, squash-merged

0. Fetch and check the remote <long-lived-branch>/<protected-branch> state before starting
   substantial work. Building several commits on a stale base causes painful divergence and
   rebase conflicts later — cheaper to catch upfront.
1. All work happens on the <long-lived-branch> — commit freely and messily; WIP commits need
   not follow commit style (they get squashed away).
2. Scope each PR to one logical change. Under squash-merge one PR = one commit on
   <protected-branch>, so a focused PR yields a clean, atomic, revertable commit. Never bundle
   unrelated changes into one PR to save a round trip.
3. When ready and tested, open a PR <long-lived-branch> → <protected-branch>. CI must pass, then
   **squash-merge**. The PR title becomes the <protected-branch> commit message, so title the PR
   as a Conventional Commit (`type(scope): subject`).
4. After merge, reset the working branch onto the protected branch so histories don't drift:
   `git switch <long-lived-branch> && git reset --hard origin/<protected-branch> && git push --force-with-lease origin <long-lived-branch>`
   This periodically rewrites the working branch out from under anyone still on an older commit —
   local automation that pushes to it should auto-rebase onto the latest remote state rather than
   just fail on a rejected push.
5. The protected branch stays releasable and is never committed to directly (except one-time
   bootstraps). Merge method is **squash only**.

## Working iteratively when you can't self-verify

Some changes can't be confirmed by the agent alone — GUI apps, interactive TUIs, visual
rendering, keybinding behavior. For that kind of work:

- Commit locally on the <long-lived-branch> as a checkpoint between attempts, but hold off on
  push/PR until the change is actually confirmed working. Each PR round-trip (CI, merge, branch
  reset/sync) is real overhead to pay for something still unvalidated.
- Once confirmed, squash the iteration into one commit representing the final validated state —
  not the trial-and-error path to get there — then push → PR → merge once.
- Squash the working branch to one commit before opening the PR even for self-verifiable work
  (`git reset --soft origin/<protected-branch> && git commit`). A PR showing twenty WIP commits
  is hard to review, even though squash-merge collapses them anyway.

Work verifiable directly — syntax checks, a dry run, non-interactive CLI behavior — doesn't need
this; the normal per-change cadence is fine there.

## Local tooling

Mirror what CI enforces locally (pre-commit hooks or equivalent) so failures surface before push,
not after — the same checks CI runs, not a subset that drifts from them.

Scope the day-to-day credential (a CLI token, not a full-admin auth session) down to what routine
commits/PRs actually need, so an agent driving `gh` (or equivalent) can't accidentally touch repo
settings, branch protection, or other administrative surfaces. Elevate explicitly only for the
one action that needs it.

Two tools worth reaching for by hand, not wired into any hook: `git cliff --bump` to preview the
exact version/changelog release automation would produce, with zero side effects, before
triggering it for real; and running CI workflows locally (`act` for GitHub Actions) instead of
pushing and waiting on a real run when iterating on the workflow files themselves.

## Releases (if the repo versions releases) — git-cliff + gh

Cut <version-scheme> (e.g. [SemVer](https://semver.org)) from Conventional Commits:

- On the working branch: `git cliff --tag <TAG> -o CHANGELOG.md`, commit as
  `chore(release): <TAG>`, PR, squash-merge.
- Tag it: `git tag -a <TAG> -m <TAG> && git push origin <TAG>`.
- Publish notes from the same source:
  `gh release create <TAG> --notes-file <(git cliff --tag <TAG> --latest --strip all)`.
