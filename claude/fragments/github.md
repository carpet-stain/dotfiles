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
5. The protected branch stays releasable and is never committed to directly (except one-time
   bootstraps). Merge method is **squash only**.

## Releases (if the repo versions releases) — git-cliff + gh

Cut <version-scheme> (e.g. [SemVer](https://semver.org)) from Conventional Commits:

- On the working branch: `git cliff --tag <TAG> -o CHANGELOG.md`, commit as
  `chore(release): <TAG>`, PR, squash-merge.
- Tag it: `git tag -a <TAG> -m <TAG> && git push origin <TAG>`.
- Publish notes from the same source:
  `gh release create <TAG> --notes-file <(git cliff --tag <TAG> --latest --strip all)`.
