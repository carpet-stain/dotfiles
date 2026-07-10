<!-- LAYER 1 — Git workflow mechanics, platform-agnostic. Canonical source: my dotfiles.
     VCS-level only: works the same on GitHub, GitLab, Bitbucket, or a bare remote.
     Platform-specific realization (gh/glab CLI, GitHub Actions, a host's specific
     squash-merge behavior) lives in the Layer 2 platform file instead (e.g. github.md). -->

> ### APPLY GUARD
> APPLY ONLY IF this repo uses git (true for nearly every repo — this is the rare-exception
> gate, not a real filter). If somehow not, ignore this entire file.
> If this repo has its own contributing/workflow doc that specifies commit or branch rules,
> that doc is AUTHORITATIVE: treat this layer as baseline and prefer the repo's doc on conflict.

> ### COMPOSE PROTOCOL (how to give a repo its own concrete git workflow doc)
> Trigger: only when the human asks to scaffold, OR a repo lacks a stated commit/branch
> workflow and one is warranted. Default to PROPOSE, don't create — suggest and wait before
> writing committed files.
> Steps:
>   1. Read this layer once as the baseline.
>   2. Write a repo-local doc (or an AGENTS.md section) that fills the <placeholders> with
>      this repo's real values: <scopes> (its module/area names), <version-scheme>, the
>      <long-lived-branch>/<protected-branch> names, and whether release automation applies.
>   3. Wire the gate so local wins: add to the repo's committed AGENTS.md:
>        "This repo's workflow doc is authoritative for commit/branch rules; treat any
>         generic git layer as baseline and prefer this repo's doc on conflict."
>      (Names NO personal path — commit-safe, true for any contributor.)
>   4. After this, the repo reads its own doc; do not re-distill this layer for that repo.

# Git Workflow

Mechanics for realizing my version-control discipline with plain git — true regardless of
hosting platform. Repo-specific values (commit scopes, version scheme, branch names) fill the
<placeholders> and live in the repo. "PR" below means a pull or merge request, whichever your
host calls it.

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

## Version Control Discipline

- **Review before committing.** Don't commit or push on your own initiative; show what changed and
  get explicit approval, then commit only what was approved.
- **Commit freely while developing** on the working branch; intermediate checkpoints are expected.
- **Main-line history is clean.** Each merged change is one clear, complete, squashed commit
  describing the whole change — not its iteration history.
- **Rebase onto latest main-line before merging.**
- **Never rewrite history you don't own.** The only sanctioned force-push is the deliberate rewrite
  of your own just-squashed branch, and it must abort if the remote moved unexpectedly.
- If the remote moved unexpectedly, stop and inspect before doing anything destructive; realign
  rather than overwrite.

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
   **squash-merge**. Title the PR as a Conventional Commit (`type(scope): subject`) — most hosts
   carry the PR title into the resulting commit message on squash-merge.
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

## Shift-left tooling and credential scope

Mirror what CI enforces locally (pre-commit hooks or equivalent) so failures surface before push,
not after — the same checks CI runs, not a subset that drifts from them.

Scope the day-to-day credential (a CLI token, not a full-admin auth session) down to what routine
commits/PRs actually need, so an agent driving the host's CLI can't accidentally touch repo
settings, branch protection, or other administrative surfaces. Elevate explicitly only for the
one action that needs it. (Concrete instance for GitHub: the Layer 2 `github.md` file.)

`git cliff --bump` is worth reaching for by hand, not wired into any hook: preview the exact
version/changelog release automation would produce, with zero side effects, before triggering it
for real.

## Releases (if the repo versions releases) — git-cliff

Cut <version-scheme> (e.g. [SemVer](https://semver.org)) from Conventional Commits:

- On the working branch: `git cliff --tag <TAG> -o CHANGELOG.md`, commit as
  `chore(release): <TAG>`, PR, squash-merge.
- Tag it: `git tag -a <TAG> -m <TAG> && git push origin <TAG>`.
- Publishing the release itself (notes, a release page) is host-specific — see the Layer 2
  platform file.

## Before Finishing, Ask

- Did I fetch and check the remote before starting substantial work?
- Is this PR scoped to one logical change, with commits following Conventional Commits?
- For unvalidated/unverifiable work, did I hold off on push/PR until it's actually confirmed?
