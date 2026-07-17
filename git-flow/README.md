# Git-flow governance template

Copier template bundling the language-agnostic layer of this repo's
git/GitHub workflow (#136) — PR guards, optional release automation, and the
scoped-token credential pattern. Decisions and rationale live on #136 and its
spike #137; this is the mechanism.

Language-agnostic base under a language overlay (e.g. the Python starter at
`../python`): apply this template first, then layer a language template on
top.

The templates write **no `.copier-answers` file**, so there is no `copier
update` path — a repo is scaffolded once and evolved directly from then on
(ADR-0020, ADR-0021 in this repo's `docs/adr/`). Later template conventions
reach an existing repo by editing it, or by re-running the retrofit below.

## Use

```sh
uvx copier copy ~/.config/dotfiles/git-flow <new-project-dir>
```

Answers the GitHub owner/repo, the protected branch name, and whether to
include release automation, then a post-generation task runs `git init` and
`lefthook install`.

## Retrofit an existing, never-templated repo

```sh
~/.config/dotfiles/scripts/retrofit-governance.sh [--python] <repo-dir>
```

`copier copy` can't do this safely — `--overwrite` replaces colliding files
(deleting the repo's real README), and the plain path prompts per file. The
script (#282) generates the template output into a temp tree and **git-merges**
it in as an unrelated history, which is the additive semantics wanted: an
absent file is created, an existing one becomes an `add/add` conflict with both
contents kept under markers for the operator to resolve, and nothing is ever
deleted. Answers are derived from the repo (origin URL, default branch, git
user); `--python` layers the Python overlay too. Re-run it later to pull a
wholesale template refresh (shared files re-conflict for you to resolve);
smaller changes are usually quicker to hand-apply. Greenfield repos don't need
it — `copier copy`/`py-new` onto an empty dir has no collisions.

## What it produces

- `.github/workflows/pr-guards.yml` — one-commit-per-PR + Conventional
  Commit subject, gated on `draft == false`
- `.github/workflows/adr-guard.yml` — a PR labeled `architecture` must
  add/modify a `docs/adr/` file, else fail; unlabeled PRs report success, so
  it's safe as a required check. `bootstrap-branch-protection.sh` (step 4
  below) makes it a required check automatically because the guard ships
  here. See the ADR scaffolding below for what a labeled PR must produce.
- `.github/workflows/lint.yml` — the base CI: a `lint` job running the
  language-agnostic linters via `just lint --tag base`, gated on
  `draft == false`. A language overlay never touches it — it ships its own
  workflow (e.g. `test.yml`) running its own lefthook tag slice (ADR-0020)
- `docs/adr/` scaffolding — `README.md` (what an ADR is, when to write one),
  `templates/template.md` (the Nygard template), `scripts/new-adr.sh` (stamps
  the next-numbered ADR from it — run via `just adr`, no adr-tools dependency),
  `.adr-dir`, and a seed `0001-record-architecture-decisions.md` so the
  directory exists in a fresh checkout
- `.github/workflows/release-prepare.yml` / `release-publish.yml` +
  `cliff.toml` (if release automation is included) — manual-dispatch version
  bump via git-cliff, a release PR, tag + GitHub release on merge
- `.github/pull_request_template.md` — the Conventional-Commit title reminder
  plus the doc-ownership checklist (decisions journal, ADR-when, supersede)
- `.github/ISSUE_TEMPLATE/` — bug / feature / spike forms whose default labels
  match the `apply-labels.sh` taxonomy
- `justfile` + `justfile.base` — the composition root (`import
'justfile.base'`, `import? 'justfile.lang'`) and the base verbs: `just lint`
  (wraps `lefthook run pre-commit --all-files`, the entry point CI shares) and
  `just adr`. An overlay drops its verbs in `justfile.lang`
- `lefthook.yml` + `lefthook-base.yml` + `lefthook-lang.yml` — the composition
  root (`extends` both), the base jobs tagged `base` (`actionlint`,
  `markdownlint-cli2`, `prettier`, `yamlfmt`, `check-envrc-local-example.sh`),
  and an empty stub an overlay overwrites with its `lang`-tagged jobs
- `.editorconfig`, `.markdownlint-cli2.yaml`, `.prettierrc.json`, `.yamlfmt` —
  the language-agnostic formatting baseline the lefthook jobs and CI enforce
- `README.md` — a starter front door filled from the copier answers, pointing
  at `docs/adr/` and `just lint` rather than restating them
- `.envrc` + `.envrc.local.example` — aliases `GH_TOKEN` to `GITHUB_TOKEN`
  for git-cliff's GitHub API lookups
- `.github/dependabot.yml` — weekly `github-actions` ecosystem updates

## What it deliberately doesn't produce

- **Branch protection.** Needs Administration-scope API access the routine
  `GH_TOKEN` deliberately lacks. Run
  `~/.config/dotfiles/scripts/bootstrap-branch-protection.sh` by hand with
  `env -u GH_TOKEN -u GITHUB_TOKEN` after generating the repo — see that script and #137's
  decision comment on #136 for why this stays a separate, explicitly-elevated
  step instead of a copier post-gen task.
- **The `RELEASE_PAT` secret.** `release-prepare.yml` needs a repo secret
  named `RELEASE_PAT` (a fine-grained PAT with Contents + Pull requests
  write) so its release PR triggers `pr-guards.yml` for real instead of
  landing in an approval-required state — see the workflow's own comments.
  Add it by hand: repo Settings → Secrets and variables → Actions.
- **Labels.** Tracked separately — see the Bootstrap runbook below.
- **Global git config** (`committemplate`, `attributes`, `config`, `ignore`).
  Those are this machine's `$XDG_CONFIG_HOME/git/*`, deployed once by
  `macos/deploy.zsh` / `linux/deploy.sh` — already in effect for every repo
  on a machine with dotfiles installed, nothing to port per-project.
- **A language build/test pipeline.** The base ships `lint.yml` for the
  language-agnostic linters (above), but building and testing are
  language-specific — a language overlay (e.g. the Python starter) ships its
  own workflow alongside it, plus its `lefthook-lang.yml` and `justfile.lang`.

## Bootstrap runbook

The full sequence from idea to a governed repo. Each step is independent
and already idempotent — deliberately a documented sequence, not one fused
script, so a future Terraform cutover (repos-as-code, tracked on #136) can
replace steps 3–4 with `terraform apply` without touching 1–2, which
Terraform can't do (it manages GitHub API-level resources, not git
working-tree file content).

1. **Create the empty repo** — `gh repo create` or the GitHub web UI. A
   deliberate human step: picking the owner/org and visibility isn't
   something to automate.
2. **Scaffold the files** — `uvx copier copy ~/.config/dotfiles/git-flow
   <dir>` (see Use, above). Layer a language template on top if applicable
   (e.g. `../python`). Push this first commit to `main` directly — a repo
   with zero commits has no `main` yet, and pushing any other branch name
   first makes GitHub adopt *that* branch as the new default instead. If
   you push a differently-named branch by mistake (e.g. via a PR flow),
   fix it with a branch rename
   (`gh api repos/{owner}/{repo}/branches/<branch>/rename -f new_name=main`),
   not another push — renaming an already-pushed branch doesn't touch
   content, so nothing needs re-review.
3. **Apply labels** — from inside the generated repo's checkout:
   `env -u GH_TOKEN -u GITHUB_TOKEN ~/.config/dotfiles/scripts/apply-labels.sh`.
4. **Apply branch protection** — same directory:
   `env -u GH_TOKEN -u GITHUB_TOKEN ~/.config/dotfiles/scripts/bootstrap-branch-protection.sh`.
   Must come after step 2: it hardcodes `single commit` + `conventional
commit` as required checks, which only exist once `pr-guards.yml` is in
   the repo — running this first leaves required checks that never report,
   permanently blocking merges. Also needs GitHub Pro or a public repo (the
   script's own comments cover this gotcha). It requires `adr guard`
   automatically too, since this template ships `adr-guard.yml`.
5. **Add the `RELEASE_PAT` secret** by hand, if release automation was
   included in step 2 — see "What it deliberately doesn't produce," above.

Steps 3 and 4 both need the elevated `env -u GH_TOKEN -u GITHUB_TOKEN` session
(routine `GH_TOKEN` deliberately lacks Issues/Administration scope; both vars
drop because `.envrc` aliases `GITHUB_TOKEN` to the same scoped token) — see
AGENTS.md's Credentials section.

## Known limitation

A generated repo is this base plus **at most one** language overlay — never
more (ADR-0020). The layers own disjoint files, composed natively: separate
workflow files for CI, `import?` for the justfile, `extends` + an
overwritable stub for lefthook, with `base`/`lang` lefthook tags splitting
the CI slices. Copier's inability to merge files across templates therefore
only bites the two files both layers still ship: `.gitignore` (the overlay
replays the base's single `.envrc.local` entry — git has no include
mechanism for tracked ignores) and the seeded `README.md` (pointer-pure and
structurally identical, so the overwrite is harmless).
