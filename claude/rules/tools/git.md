<!-- Git workflow mechanics, platform-agnostic. Canonical source: my dotfiles.
     VCS-level only: same on GitHub, GitLab, Bitbucket, or a bare remote. Platform specifics
     (gh/glab, Actions, a host's squash-merge behavior) live in the platform file (github.md).
     Rationale: claude/README.md. -->

> ### GATE
>
> Applies only if this repo uses git — true for nearly every repo, so this is the rare-exception
> gate, not a real filter. If not, ignore this file.

> ### LOCAL-WINS
>
> If this repo has its own commit/branch-workflow doc, that doc is AUTHORITATIVE: treat this as
> baseline and prefer the repo's doc on conflict.

> ### COMPOSE — give a repo its own concrete git workflow doc
>
> Trigger: the human asks to scaffold, OR a repo lacks a stated workflow and one is warranted.
> PROPOSE, don't create — suggest and wait. Steps: (1) read this as baseline; (2) write a
> repo-local doc filling the <placeholders> — <scopes>, <version-scheme>, <protected-branch>,
> whether release automation applies; (3) add to the repo's AGENTS.md that its workflow doc is
> authoritative over generic git conventions (name no personal path); (4) after this the repo
> reads its own doc — don't re-distill.

# Git Workflow

Repo-specific values (scopes, version scheme, branch names) fill the <placeholders> and live in
the repo. "PR" means a pull or merge request, whichever your host calls it.

## Commits — Conventional Commits

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): description`,
imperative lowercase subject ≤50 chars (hard limit 72); `type` ∈ feat/fix/docs/style/refactor/perf/
test/build/ci/chore; `scope` from this repo's <scopes>. Breaking change: `type!:` or a
`BREAKING CHANGE:` footer. Blank line, then a body wrapped at 72 explaining _what_ and _why_, never
_how_. `Co-authored-by:` per human contributor; never AI attribution. One logical change per
commit; propose the split before committing.

## Version Control Discipline

- Don't commit or push on your own initiative — show what changed, get approval, commit only that.
- Commit freely on the working branch; main-line history stays clean (one squashed commit per
  merged change, not its iteration history).
- Rebase onto latest main-line before merging.
- Never rewrite history you don't own. The only sanctioned force-push is your own just-squashed
  branch, and it aborts if the remote moved. If the remote moved unexpectedly, stop and inspect
  before anything destructive — realign, don't overwrite.

## Branch & PR model — short-lived feature branches + protected main, rebase-merged

1. Fetch and check the remote <protected-branch> before branching — a stale base means painful
   divergence later. Branch off it per change; the branch is single-use and short-lived.
2. Open the PR/MR as soon as a branch and first commit exist, not after the final squash. Journal
   decisions, gotchas, decision forks, and retractions as PR/MR comments while work proceeds — the
   PR/MR becomes the real-time record, not a postmortem written at the end. Host-specific mechanics
   for keeping checks quiet during this early/WIP window live in the platform file.
3. Commit freely on the feature branch — WIP commits needn't follow the commit style, since only
   the final squashed commit reaches <protected-branch>.
4. One logical change per PR. Never bundle unrelated changes to save a round trip.
5. When ready and tested, squash the branch to exactly one Conventional Commit
   (`git reset --soft origin/<protected-branch> && git commit`), then finalize (mark ready for
   review) — the commit reaches its final shape here, and CI gates on the PR being exactly one
   commit with a Conventional-Commit subject — the two checks rebase-merge relies on, since the
   host won't rewrite the message the way squash-merge would.
6. Once green, **rebase-merge**: your single commit lands on <protected-branch> verbatim, and the
   branch auto-deletes. No branch reuse or reset step needed — the next change starts a fresh
   branch off <protected-branch>.
7. <protected-branch> stays releasable, never committed to directly. Merge method is rebase-merge
   only, enforced by the single-commit + Conventional-Commit checks.

## Working iteratively when you can't self-verify

Open-PR-early (step 2) still applies here — the draft PR opens at the first commit regardless of
how verifiable the change is, with no exception: always open it via the draft path (e.g.
`git pr --draft`), never the plain/no-flag path, even when the change is already done and
verified. What this section scopes is _finalizing_ (marking ready for review): draft means the
agent is still working, ready-for-review means it's the human's turn — that handoff is itself the
"your turn" signal, so squash to one commit (`git reset --soft origin/<protected-branch> && git
commit`) and finalize at handoff for all work, verifiable or not. For changes the agent can't
confirm alone (GUI, TUI, rendering, keybindings), the human's confirmation folds into reviewing
the ready PR rather than gating the flip to ready — finalizing also triggers CI, so the human
picks it up with checks already run. Staying in draft at handoff is the explicit exception, not
the default: only when the agent specifically needs the human to test something _before_ code
review can happen, and it says so in the handoff message.

## Shift-left tooling and credential scope

Mirror what CI enforces locally (pre-commit or equivalent) — the same checks, not a drifting
subset. Scope the day-to-day credential (a CLI token, not a full-admin session) to what routine
commits/PRs need, so an agent driving the host CLI can't touch repo settings or branch protection;
elevate explicitly only for the one action that needs it. `git cliff --bump` previews the exact
version/changelog release automation would compute, with zero side effects — reach for it by hand.
If the repo's changelog resolves PR links via the host's API (below), this preview is
network-dependent by default; `--offline` (or `GIT_CLIFF_OFFLINE`) skips those lookups when that
matters.

## Releases (if the repo versions releases) — git-cliff

Cut <version-scheme> from Conventional Commits: on a release branch `git cliff --tag <TAG> -o
CHANGELOG.md`, commit as `chore(release): <TAG>`, PR, rebase-merge, then `git tag -a <TAG> -m <TAG>
&& git push origin <TAG>`. Publishing notes is host-specific — see the platform file.

Resolve PR/MR changelog links via the host's API at changelog-generation time, not by encoding
them into the commit message: rebase-merge (or any strategy that preserves the author's SHA)
means a pre-merge text convention can't survive history rewrites the host itself doesn't do, but
the host tracks the commit↔PR association server-side regardless of merge strategy, so a
generation-time lookup is the durable source, not the commit text. Host-specific config lives in
the platform file.
