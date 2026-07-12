# Git-flow governance template

Copier template bundling the language-agnostic layer of this repo's
git/GitHub workflow (#136) — PR guards, optional release automation, and the
scoped-token credential pattern. Decisions and rationale live on #136 and its
spike #137; this is the mechanism.

Language-agnostic base under a language overlay (e.g. the Python starter at
`../python`): apply this template first, then layer a language template on
top. Each template keeps its own namespaced answers file
(`.copier-answers.git-flow.yml` here) so `copier update` can track them
independently.

## Use

```sh
uvx copier copy ~/.config/dotfiles/git-flow <new-project-dir>
```

Answers the GitHub owner/repo, the protected branch name, and whether to
include release automation, then a post-generation task runs `git init` and
`lefthook install`.

## Update an existing generated project

```sh
uvx copier update --answers-file .copier-answers.git-flow.yml
```

## What it produces

- `.github/workflows/pr-guards.yml` — one-commit-per-PR + Conventional
  Commit subject, gated on `draft == false`
- `.github/workflows/release-prepare.yml` / `release-publish.yml` +
  `cliff.toml` (if release automation is included) — manual-dispatch version
  bump via git-cliff, a release PR, tag + GitHub release on merge
- `lefthook.yml` — `actionlint` on the bundled workflow files,
  `check-envrc-local-example.sh` on commit and push
- `.envrc` + `.envrc.local.example` — aliases `GH_TOKEN` to `GITHUB_TOKEN`
  for git-cliff's GitHub API lookups
- `.github/dependabot.yml` — weekly `github-actions` ecosystem updates

## What it deliberately doesn't produce

- **Branch protection.** Needs Administration-scope API access the routine
  `GH_TOKEN` deliberately lacks. Run
  `~/.config/dotfiles/scripts/bootstrap-branch-protection.sh` by hand with
  `env -u GH_TOKEN` after generating the repo — see that script and #137's
  decision comment on #136 for why this stays a separate, explicitly-elevated
  step instead of a copier post-gen task.
- **The `RELEASE_PAT` secret.** `release-prepare.yml` needs a repo secret
  named `RELEASE_PAT` (a fine-grained PAT with Contents + Pull requests
  write) so its release PR triggers `pr-guards.yml` for real instead of
  landing in an approval-required state — see the workflow's own comments.
  Add it by hand: repo Settings → Secrets and variables → Actions.
- **Labels.** Tracked separately — labels-as-code is its own #136 build item,
  not yet built.
- **Global git config** (`committemplate`, `attributes`, `config`, `ignore`).
  Those are this machine's `$XDG_CONFIG_HOME/git/*`, deployed once by
  `macos/deploy.zsh` / `linux/deploy.sh` — already in effect for every repo
  on a machine with dotfiles installed, nothing to port per-project.
- **A CI test/lint pipeline.** Language-specific; the Python starter template
  ships its own `ci.yml`.

## Known limitation

`lefthook.yml` and `.gitignore` are plain files, not merged across
templates — combining this with a language overlay that ships its own
copies needs a one-time hand-merge, the same class of limitation the Python
starter's `pyproject.toml` has.
