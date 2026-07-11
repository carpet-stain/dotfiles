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

| Path                                         | Reason                                                                                                                                                            |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.zshenv`                                    | zsh's fixed entry point — always read from `$HOME`                                                                                                                |
| `.ssh/`                                      | Symlink → `~/.config/ssh/`; config tracked in `ssh/config`, keys gitignored                                                                                       |
| `.claude.json` legacy path                   | Claude Code now honors `CLAUDE_CONFIG_DIR` → `$XDG_CONFIG_HOME/claude` (set in `.zshenv`); config is XDG. A stale `~/.claude*` may remain from before the switch. |
| `.vscode-oss/`, `.vscode-oss-shared/`        | Claude Code desktop app data — no XDG support                                                                                                                     |
| `.CFUserTextEncoding`, `.DS_Store`, `.Trash` | macOS system — not configurable                                                                                                                                   |
| `.zsh_sessions/`, `.bash_sessions/`          | Terminal.app session restore — suppressed via `SHELL_SESSIONS_DISABLE=1`                                                                                          |

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
  installs Homebrew + Brewfile, syncs submodules, builds caches/terminfo.
- `linux/deploy.sh` — Debian bootstrap: same shape as `macos/deploy.zsh` but
  bash, apt (`linux/Aptfile`) instead of Homebrew, and GitHub release
  binaries for tools too old/missing in Debian's repos (neovim, git-delta,
  zellij, eza). Both scripts hand-maintain their own directory/runner
  logic — no shared lib between them; when one changes, check the other.
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
- Concrete realization of Propose Before Implementing for this repo: editing
  `claude/rules/*.md`, `README.md`'s voice, or this file itself is opinion/judgment
  content — discuss before writing or committing. zsh/nvim/tool-config tweaks are
  mechanical — proceed and report.

## Verifying changes

This repo has no test suite or architectural layers to test against — Testing
By Layer's underlying idea (different kinds of behavior need different kinds
of proof) still applies, just mapped onto kinds of _changes_ rather than
architectural layers:

- **Syntax/lint/format**: `lefthook run pre-commit --all-files` runs every
  check listed under "Linters/formatters by file type" below — the same
  checks `ci.yml`'s `lint` job runs.
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
> scopes = `zsh, zellij, git, nvim, macos, theme`; version scheme = SemVer; branches =
> short-lived feature branches → `main` (protected). It's baseline; the rules below
> win here and are complete on their own.

Follow `git/committemplate` and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Every commit:

1. **Subject**: `type(scope): description`
   - `type` ∈ feat, fix, docs, style, refactor, perf, test, build, ci, chore
   - `scope` (optional): repo area — zsh, zellij, git, nvim, macos, theme
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

`lefthook.yml` is the single source of truth for lint/format checks — run
locally before push instead of after, and `ci.yml`'s `lint` job runs the exact
same `lefthook run pre-commit --all-files` rather than re-implementing each
check as a separate CI step, so CI can't drift from what a contributor's hook
already runs.

Installed automatically by `macos/deploy.zsh`'s `install_lefthook_hooks`
step; run `lefthook run pre-commit --all-files` to check everything at once.

### Linters/formatters by file type

One tool per type, installed via `macos/Brewfile` and shared between
`lefthook.yml`, `ci.yml`, and nvim's `conform`/`nvim-lint` — not a second
Mason-managed copy. No silent gaps: every tracked file type is either covered
below or explicitly called out as skipped.

| Type             | Lint                | Format     | Notes                                                                |
| ---------------- | ------------------- | ---------- | -------------------------------------------------------------------- |
| lua              | `selene`            | `stylua`   | `nvim/selene.toml` + `nvim/vim.yml` define the `vim` global          |
| zsh              | `zsh -n`            | —          | syntax-check only; no zsh formatter adopted                          |
| sh / bash        | `shellcheck`        | `shfmt`    | `-i 2 -ci`; zsh is excluded from shellcheck (false positives)        |
| toml             | `taplo`             | `taplo`    |                                                                      |
| yaml (config)    | —                   | `yamlfmt`  | `.yamlfmt` sets `retain_line_breaks` to preserve blank-line grouping |
| yaml (workflows) | `actionlint`        | —          | semantic checks, not styled by `yamlfmt`                             |
| md               | `markdownlint-cli2` | `prettier` | `CHANGELOG.md` is excluded (git-cliff generated)                     |
| json             | —                   | —          | out of scope — not in the original ask, only 3 files                 |
| kdl              | —                   | —          | skipped — no mature tooling exists                                   |
| js               | —                   | —          | skipped — one file, not worth a tool                                 |

Two more tools worth reaching for by hand, not wired into any hook:

- `git cliff --bump` — preview the exact version/changelog `release-prepare.yml`
  would compute, with zero side effects, before actually triggering it.
- `act` — runs the GitHub Actions workflows themselves locally (via Docker),
  for testing workflow changes without pushing and waiting on real CI.

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

## Git workflow

> Concrete realization of **git.md**'s Branch & PR model
> (`claude/rules/tools/git.md`) for this repo: short-lived feature branches,
> protected branch = `main`, version scheme = SemVer. It's baseline; the
> rules below win here and are complete on their own.

Branching model: **short-lived feature branches + protected `main`**,
rebase-merged. You own the commit that lands on `main` — GitHub doesn't rewrite it.

1. Branch off `main` for each change: `git switch -c <name> origin/main`. Commit
   freely while working — WIP commits needn't follow the commit style.
2. **One logical change per PR.** Never bundle unrelated changes into a single PR
   just to save a round trip.
3. When ready and tested, **squash the branch to exactly one Conventional Commit**
   (`git reset --soft origin/main && git commit`), then open a PR → `main`. CI gates
   the PR on being exactly one commit (`single commit`) whose subject is a
   Conventional Commit (`conventional commit`); once green, **rebase-merge** and your
   single commit lands on `main` verbatim. The branch auto-deletes on merge.
4. `main` stays releasable, and cutting a release is automated — you decide
   _when_, the workflows do the busywork ([SemVer](https://semver.org) versions
   computed from the Conventional Commits by [git-cliff](https://git-cliff.org)):
   - **Dispatch `release-prepare.yml`** — `gh workflow run release-prepare.yml -f bump=auto`
     (or the Actions UI; `auto` lets git-cliff pick the bump). It computes the
     next version, regenerates `CHANGELOG.md`, and opens a `release/vX.Y.Z` PR.
   - **Review and rebase-merge that PR.** The merge triggers
     `release-publish.yml`, which tags `vX.Y.Z`, creates the GitHub release with
     notes, and deletes the release branch.
   - Preview with zero side effects first: `git cliff --bumped-version` (the next
     version) or `git cliff --unreleased --bump` (the changelog it will write).

   The two `.github/workflows/release-*.yml` files own the mechanism and the
   _why_ of each choice — read their comments; this section is just the
   operator's procedure. They automate the equivalent by-hand steps
   (`git cliff --tag vX.Y.Z -o CHANGELOG.md` → commit `chore(release): vX.Y.Z`
   → tag → `gh release create`), so a release can still be cut manually if the
   automation is ever unavailable.

`main` is never committed to directly (except one-time bootstraps). Merge method
is **squash only**; rebase-merge stays disabled and is a deliberate, temporary
exception used only to land a series of already-clean commits atomically.
