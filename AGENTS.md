# AGENTS.md

Guidance for AI assistants working in this repo (repo-specific).
Vendor-neutral; the root `CLAUDE.md` is a gitignored symlink to this file.

> **Note:** this repo also has a `claude/` directory unrelated to the root
> `CLAUDE.md` symlink above. `claude/rules/*.md` are the global agent-config
> files (tracked, deployed to `$CLAUDE_CONFIG_DIR/rules`, where Claude
> Code auto-discovers and loads them) — see `claude/README.md`.

## Precedence: this repo's own docs win over the generic files

If the agent supplies the generic global files (universal philosophy, Go, GitHub mechanics),
this repo's own documents are **authoritative** where they overlap — treat any generic file
as baseline and prefer this file and the sections below on conflict. The universal philosophy
is not _overridden_; this repo illustrates how it is realized. A contributor without any
of the global files loses nothing — this guide is the full story.

## What this is

Personal macOS dotfiles: Ghostty + Zellij + zsh + Neovim, themed Catppuccin
Mocha throughout, XDG-compliant. Primary target is macOS on Apple Silicon.
Debian (`linux/deploy.sh`) is a secondary target — mainly used in disposable
OrbStack VMs — and doesn't carry Ghostty or Homebrew.

## Philosophy

- **Best tool for the job.** Prefer purpose-built modern tools (fd, rg, eza, bat,
  delta, zoxide, fzf) over defaults — this repo's concrete realization of the
  universal Small, Composable Tools principle.
- **No bloat.** Every setting earns its place — Simplicity First's "no
  speculative additions" applied to config. Delete dead config instead of
  letting it accumulate, the same discipline Refactoring asks of code.
- **Homebrew-first.** Install packages via Homebrew. Only when Homebrew lacks a
  package does it become a git submodule. No dotfile manager or framework —
  Powerlevel10k is the sole exception. On Linux, where there's no Homebrew,
  `linux/deploy.sh` installs via apt where possible and falls back to
  git-cloning zsh plugins straight to `$XDG_DATA_HOME/zsh/plugins` (no
  submodules — that dir's not tracked in this repo).
- **XDG discipline.** Keep `$HOME` clean: only `.zshenv` lives there, everything
  else goes under `$XDG_{CONFIG,CACHE,DATA,STATE}_HOME`. Respect the distinction —
  config vs cache vs data vs state. Documented exceptions below.
- **Portable, extendable, quick to install.** A fresh machine should reach a
  working setup by cloning and running the deploy script.

### XDG exceptions

Entries that must stay in `$HOME` despite the XDG rule:

| Path                                         | Reason                                                                                                                                                                                                                                                                                                                                                               |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.zshenv`                                    | zsh's fixed entry point — always read from `$HOME`                                                                                                                                                                                                                                                                                                                   |
| `.ssh/`                                      | Symlink → `~/.config/ssh/`; config tracked in `ssh/config`, keys gitignored                                                                                                                                                                                                                                                                                          |
| `.claude/`                                   | Claude Code honors `CLAUDE_CONFIG_DIR` → `$XDG_CONFIG_HOME/claude` (set in `.zshenv`) for its main config. Its daemon, telemetry, and background-job subsystems don't — they hardcode or fail to inherit `~/.claude` in spawned subprocesses, an upstream limitation as of 2.1.197. Expect `daemon/`, `daemon-auth-*`, `telemetry/`, `jobs/` to keep appearing here. |
| `.vscode-oss/`, `.vscode-oss-shared/`        | Claude Code desktop app data — no XDG support                                                                                                                                                                                                                                                                                                                        |
| `.CFUserTextEncoding`, `.DS_Store`, `.Trash` | macOS system — not configurable                                                                                                                                                                                                                                                                                                                                      |
| `.zsh_sessions/`, `.bash_sessions/`          | Terminal.app session restore — suppressed via `SHELL_SESSIONS_DISABLE=1`                                                                                                                                                                                                                                                                                             |
| `.terminfo/`                                 | ncurses' default search path covers `~/.terminfo` but not `$XDG_DATA_HOME`; `linux/deploy.sh` compiles Ghostty's `xterm-ghostty` entry here so it resolves in any shell (bash, zsh, sudo, cron) without `$TERMINFO` being exported                                                                                                                                   |

## Structure & conventions

- `zsh/.zshenv` — sourced on every shell: env vars, PATH, tool config. No output,
  no tty assumptions.
- `zsh/.zshrc` — interactive only. Acts as a table of contents that sources
  `rc.d/` modules in dependency order.
- `zsh/rc.d/` — one concern per file (options, widgets, keybindings, aliases,
  completions, fzf-tab, powerlevel10k).
- `zsh/env.d/` — sourced always (e.g. `ls_colors.zsh`).
- `zsh/fpath/` — custom zle widgets and completions, autoloaded.
- `theme/` — Catppuccin submodules per tool (bat, delta, zsh-fsh). Ghostty uses
  its built-in `catppuccin-mocha` theme, no submodule.
- `zellij/` — `config.kdl` (keybinds, kitty-keyboard-protocol disabled for nvim
  compat), `layouts/default.kdl` (zjstatus status bar), `themes/catppuccin.kdl`
  (vendored, not a submodule — same rationale as `theme/`).
- `nvim/` — LazyVim on `lazy.nvim`. Official language extras are imported in
  `lua/config/lazy.lua` (`lazyvim.plugins.extras.lang.*`); everything else
  custom goes in `lua/plugins/*.lua`, one file per concern. Mason's
  `ensure_installed` must list LSP/tool names explicitly — the indirect
  auto-install via `nvim-lspconfig`'s `servers` table doesn't reliably fire
  during a headless `deploy.zsh` run. `lazy-lock.json` is tracked and
  symlinked in `deploy.zsh`, matching LazyVim's own recommended practice.
- `macos/deploy.zsh` — macOS bootstrap: creates XDG dirs, symlinks configs,
  installs Homebrew + Brewfile, syncs submodules, enables git background
  maintenance, builds caches/terminfo.
- `linux/deploy.sh` — Debian bootstrap: same shape as `macos/deploy.zsh` but
  bash, apt (`linux/Aptfile`) instead of Homebrew, and GitHub release
  binaries for tools too old/missing in Debian's repos (neovim, git-delta,
  zellij, eza). Both scripts hand-maintain their own directory/runner
  logic — no shared lib between them; when one changes, check the other.
- `python/` — copier template for bootstrapping a packaged, reproducibility-gated
  Python 3 project (uv + hatchling + ruff + pyright + pytest + lefthook + CI;
  decisions and rationale on #129). Run via `py-new <new-project-dir>`
  (`scripts/py-new.sh`, symlinked to `~/.local/bin` by `macos/deploy.zsh` —
  macOS only, since Linux doesn't carry `uv` yet). The wrapper always passes
  copier's `--trust` flag: the template's post-gen tasks (`uv python pin`,
  `uv sync`, `git init`, `lefthook install`) are what make the result actually
  deployment-ready, and copier silently skips all of them without `--trust` —
  no error, just a project missing its lock file and git hooks.
- Both deploy scripts run every step through a `required()`/`optional()`
  wrapper: critical steps (creating dirs, symlinking configs) abort loud on
  failure; best-effort steps (a specific Brewfile package, a headless nvim
  bootstrap) log and continue. Concrete realization of Logs Are For
  Diagnosis, Output Is For Humans — a failed `optional()` step is visible
  in the run output without stopping the whole deploy.
- Section headers use the ASCII box style: `# +------+`.
- Keep ordering dependencies explicit and commented (e.g. "must come after
  compinit").

## When editing

- Read a file (and anything it depends on) before changing it.
- When a change spans files, update all of them (e.g. moving a path in `.zshenv`
  means updating `deploy.zsh`). Reconcile, don't leave drift.
- Fix bugs found along the way, but call them out.
- Summarize what changed and why — a short table beats prose.
- Prefer the change that removes a setting over the one that adds one.
- Before deleting or simplifying surprising, unexplained code, trace its
  provenance (Verify, Don't Trust's history-recovery guidance): `git blame`
  → `git show <sha>` → `gh pr view <n> --comments` → `gh issue view <n>`.
  Rebase-merge, git-cliff's PR-link resolution, and draft-PR journaling keep
  that chain intact end to end here, so the traversal is worth it.
- Concrete realization of Propose Before Implementing for this repo: editing
  `claude/rules/*.md`, `README.md`'s voice, or this file itself is opinion/judgment
  content — discuss before writing or committing. zsh/nvim/tool-config tweaks are
  mechanical — proceed and report.

## Verifying changes

This repo has no test suite or architectural layers to test against — Testing
By Layer's underlying idea (different kinds of behavior need different kinds
of proof) still applies, just mapped onto kinds of _changes_ rather than
architectural layers:

- **Syntax/lint/format**: `lefthook run pre-commit --all-files` — see
  "Local tooling" below for the tool list and why it mirrors CI.
- **Runtime behavior for nvim plugin config**: launch the real deployed config
  headlessly and query the plugin's own merged config to confirm an option
  actually took effect, e.g. `nvim --headless -c "luafile <script>"` invoking
  the relevant `:Command` and reading back its Lua module state, not just that
  the file parses.
- **Claude Code config changes** (`claude/rules/*.md`, deploy symlinking):
  check `/memory` in a real session lists the expected rules files loaded from
  `$CLAUDE_CONFIG_DIR/rules`.
- **Deploy script changes**: re-run `deploy.zsh`/`deploy.sh` and confirm it's
  idempotent — a second run should be clean, not error or duplicate work.

## Commit style

> Concrete realization of **git.md** (`claude/rules/tools/git.md`) for this repo:
> scopes = `zsh, zellij, git, nvim, macos, theme, python`; version scheme = SemVer; branches =
> short-lived feature branches → `main` (protected). It's baseline; the rules below
> win here and are complete on their own.

Follow `git/committemplate` and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Every commit:

1. **Subject**: `type(scope): description`
   - `type` is a Conventional Commit type (enforced by
     `.github/workflows/pr-guards.yml`'s `conventional commit` check —
     CI-only, no local mirror; see it for the exact list)
   - `scope` (optional): repo area — zsh, zellij, git, nvim, macos, theme, python
   - `description`: imperative, lowercase, no trailing period; keep the whole
     line ≤50 chars where possible (hard limit 72)
   - Breaking change: `type!:` or a `BREAKING CHANGE:` footer
   - Good: `fix(zsh): bind arrow keys via terminfo`
   - Bad: `fixed arrow keys` (no type, past tense, vague)
2. **Blank line** between subject and body.
3. **Body** (wrap at 72 chars): explain _what_ and _why_, never _how_ — the diff
   shows how. Omit only for trivial, self-evident changes.
4. **Trailers** (optional): add a `Co-authored-by: Name <email>` line for each
   human contributor, one blank line before the footer block. Do not add AI or
   assistant attribution.

Scope each commit to one logical change — prefer several focused commits over one
sweeping commit. Propose the split and messages before committing.

## Local tooling (shift-left)

> Concrete realization of two files: the shift-left-CI-mirroring and credential-scoping
> guidance in **git.md** (`claude/rules/tools/git.md`), plus the GitHub-specific
> instances of it — `act`, GitHub Actions workflow linting — in **github.md**
> (`claude/rules/platform/github.md`).

`lefthook.yml` is the single source of truth for lint/format checks —
`ci.yml`'s `lint` job runs the exact same `lefthook run pre-commit
--all-files` rather than re-implementing each check, so CI can't drift from
what a contributor's hook already runs.

Installed automatically by `macos/deploy.zsh`'s `install_lefthook_hooks`
step; run `lefthook run pre-commit --all-files` to check everything at once.

### Linters/formatters by file type

`lefthook.yml` is the exact source for which tool lints/formats which file
type — installed via `macos/Brewfile`, shared with `ci.yml`'s `lint` job and
nvim's `conform`/`nvim-lint` (not a second Mason-managed copy). Worth calling
out beyond what the config shows: zsh has no formatter, `zsh -n` is
syntax-check only; shellcheck excludes zsh (false positives); markdownlint
and prettier skip `CHANGELOG.md` (git-cliff generated); json (3 files),
kdl, and js (one file) are deliberately unstyled — not enough surface to
justify a tool.

Three more tools worth reaching for by hand, not wired into any hook:

- `git cliff --bump` — preview the exact version/changelog `release-prepare.yml`
  would compute, zero side effects. Network-dependent by default (resolves
  PR links via `cliff.toml`'s `[remote.github]`, using `GITHUB_TOKEN` — see
  "Credentials" below); pass `--offline` to skip that.
- `act` — runs the GitHub Actions workflows themselves locally (via Docker),
  for testing workflow changes without pushing and waiting on real CI. Needs
  a Docker socket, which macOS gets from Colima (`COLIMA_HOME`, see
  `.zshenv`), not Docker Desktop — a headless, license-free VM that stays
  down unless something's using it. Run `scripts/act-run.sh <act args>`
  rather than `act` directly: it starts Colima on demand, runs act, and
  stops Colima again only if it was the one that started it, so repeated
  runs don't re-pay the VM boot. `colima stop` tears it down explicitly when
  you're done. `actrc` (repo root, symlinked to `$XDG_CONFIG_HOME/act/actrc`
  by `deploy.zsh`) pins the runner image so act doesn't pull its own
  multi-GB default. Linux (`linux/deploy.sh`) has no Colima — its disposable
  OrbStack VMs are ephemeral dev environments, not a fit for nested
  virtualization just to run act, so this is macOS-only.
- `scripts/bootstrap-branch-protection.sh` — idempotent branch-protection
  ruleset bootstrap. Needs Administration scope the routine `GH_TOKEN` lacks
  — run with `env -u GH_TOKEN`. Not wired into CI; run manually once a
  repo's checks are set up.
- `scripts/apply-labels.sh` — idempotent label-taxonomy bootstrap
  (`scripts/labels.json`), upsert-only. Same `env -u GH_TOKEN`, manual,
  one-time convention; see `git-flow/`'s bootstrap runbook for how the two
  compose with the copier template.

### Credentials: `.envrc` / `.envrc.local`

Concrete realization of three files: the credential-scoping _principle_ in
**git.md** (`claude/rules/tools/git.md`), its GitHub-specific instance in
**github.md** (`claude/rules/platform/github.md`) — routine `gh` usage in
this repo never has admin rights to lose — and Security By Default's rule
(`claude/rules/universal/engineering-practices.md`) that secrets live in
an environment file, gitignored, never hardcoded.

`gh` CLI defaults to a scoped-down fine-grained PAT (Contents/Pull
requests/Actions read-write, no Administration) via `GH_TOKEN`, loaded by
`direnv` from `.envrc.local` (gitignored — never commit a real token) rather
than the full-admin `gh auth login` session, so day-to-day work in this repo
can't accidentally touch repo settings. `.envrc.local.example` is the tracked
template — copy it to `.envrc.local` and fill in a real token (every export
line in the template itself must stay empty; a pre-commit hook enforces both
that and that the template hasn't drifted from `.envrc.local`'s structure).
Use `env -u GH_TOKEN gh ...` for anything that actually needs the full-admin
session (e.g. changing branch protection).

This guarantee needs `GH_TOKEN` loaded — direnv only fires for interactive
shells, so non-interactive ones (scripts, cron, an agent's tool shell) used
to fall back to `gh auth login`'s broader session instead (#160).
`zsh/.zshenv` now runs `direnv export` eagerly for every shell to fix that.

`git-cliff` reads its GitHub token from a differently-named env var
(`GITHUB_TOKEN`, not `GH_TOKEN`) — `.envrc` aliases `GITHUB_TOKEN` to the same
scoped `GH_TOKEN` automatically (no second credential to manage); see
`claude/rules/platform/github.md`'s "Changelog PR links" section.

## Git workflow

> Concrete realization of **git.md**'s Branch & PR model
> (`claude/rules/tools/git.md`) for this repo: short-lived feature branches,
> protected branch = `main`, version scheme = SemVer. It's baseline; the
> rules below win here and are complete on their own.

Branching model: **short-lived feature branches + protected `main`**,
rebase-merged. You own the commit that lands on `main` — GitHub doesn't rewrite it.

1. Branch off `main` for each change: `git new <name>` (fetches `origin/main`
   fresh, then branches off it — starting from a stale base is structurally
   impossible; see `git-new.sh`). Once the first commit exists, open a
   **draft PR right away** with `git pr --draft`
   (errors loudly instead of guessing if a PR already exists for the branch —
   "did you mean to finalize? run: git pr"). Journal decisions, gotchas, and
   retractions as PR comments as work proceeds — the PR is the real-time
   record, not something written after the fact.
2. Commit freely while working — WIP commits needn't follow the commit style.
   `pr-guards.yml`'s commit-count and subject-format gates skip while the PR
   is a draft, so WIP pushes stay quiet.
3. **One logical change per PR.** Never bundle unrelated changes into a single PR
   just to save a round trip.
4. When ready and tested, **squash to exactly one Conventional Commit**
   with `git squash` (rebases onto `origin/main` before collapsing — see
   `git-squash.sh` for why reset-before-rebase is unsafe), then finalize
   with `git pr` (re-fetches, rebases, flips the PR ready, force-pushes —
   see `git-pr-link.sh` for why finalize re-checks the base and fails loud
   on conflict rather than pushing a stale commit). PR links in the
   changelog resolve from GitHub's own commit↔PR association at generation
   time (`github.md`'s "Changelog PR links"), so no subject amend is
   needed. Once green, **rebase-merge** lands your single commit on `main`
   verbatim; the branch auto-deletes.
5. `main` stays releasable; cutting a release is automated
   ([SemVer](https://semver.org) computed from Conventional Commits by
   [git-cliff](https://git-cliff.org)):
   - Preview free: `git cliff --bumped-version` / `--unreleased --bump`
     (needs `GITHUB_TOKEN`, or `--offline` — see "Local tooling").
   - **Dispatch `release-prepare.yml`** (`gh workflow run release-prepare.yml
-f bump=auto`) — computes the version, regenerates `CHANGELOG.md`, opens
     a `release/vX.Y.Z` PR.
   - **Review, then rebase-merge that PR.** Triggers `release-publish.yml`:
     tags, creates the GitHub release, deletes the release branch.

   The `.github/workflows/release-*.yml` files own the mechanism and why —
   read their comments. Equivalent by-hand steps exist if automation is ever
   unavailable: `git cliff --tag vX.Y.Z -o CHANGELOG.md` → commit → tag →
   `gh release create`.

Local `main` is otherwise vestigial in this branch model — every change branches
off `origin/main` directly via `git new`. Reach for `git sync` by hand
(`git fetch --prune origin && git switch main && git merge --ff-only origin/main`;
safe/loud under `merge.ff=only`; see `git-sync.sh`) when tooling or sanity wants a
current local `main` — it's not part of the per-change flow.

`main` is never committed to directly (except one-time bootstraps). Merge method
is **rebase-merge only**, gated by `pr-guards.yml`'s single-commit and
Conventional-Commit checks — every PR lands as the one already-squashed,
already-titled commit you pushed, verbatim.
