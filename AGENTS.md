# AGENTS.md

Guidance for AI assistants working in this repo (Layer 3 — repo-specific).
Vendor-neutral; the root `CLAUDE.md` is a gitignored symlink to this file.

> **Note:** this repo also has a `claude/` directory unrelated to the root
> `CLAUDE.md` symlink above. `claude/rules/*.md` are the global agent-config
> layer files (tracked, deployed to `$CLAUDE_CONFIG_DIR/rules`, where Claude
> Code auto-discovers and loads them) — see `claude/README.md`.

## Precedence: this repo's own docs win over generic layers

If the agent supplies generic global layers (universal philosophy, Go, GitHub mechanics),
this repo's own documents are **authoritative** where they overlap — treat any generic layer
as baseline and prefer this file and the sections below on conflict. The universal philosophy
layer is not *overridden*; this repo illustrates how it is realized. A contributor without any
global layers loses nothing — this guide is the full story.

## What this is

Personal macOS dotfiles: Ghostty + Zellij + zsh + Neovim, themed Catppuccin
Mocha throughout, XDG-compliant. Primary target is macOS on Apple Silicon.
Debian (`linux/deploy.sh`) is a secondary target — mainly used in disposable
OrbStack VMs — and doesn't carry Ghostty or Homebrew.

## Philosophy

- **Best tool for the job.** Prefer purpose-built modern tools (fd, rg, eza, bat,
  delta, zoxide, fzf) over defaults — this repo's concrete realization of the
  universal layer's Small, Composable Tools principle.
- **No bloat.** Every setting earns its place; delete dead config instead of
  letting it accumulate. Concrete realization of Simplicity First for a repo
  that's entirely configuration.
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

| Path | Reason |
|---|---|
| `.zshenv` | zsh's fixed entry point — always read from `$HOME` |
| `.ssh/` | Symlink → `~/.config/ssh/`; config tracked in `ssh/config`, keys gitignored |
| `.claude.json` legacy path | Claude Code now honors `CLAUDE_CONFIG_DIR` → `$XDG_CONFIG_HOME/claude` (set in `.zshenv`); config is XDG. A stale `~/.claude*` may remain from before the switch. |
| `.vscode-oss/`, `.vscode-oss-shared/` | Claude Code desktop app data — no XDG support |
| `.CFUserTextEncoding`, `.DS_Store`, `.Trash` | macOS system — not configurable |
| `.zsh_sessions/`, `.bash_sessions/` | Terminal.app session restore — suppressed via `SHELL_SESSIONS_DISABLE=1` |

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

Concrete realization of Testing By Layer for a repo with no test suite:

- **Syntax**: `zsh -n` on zsh files, `shellcheck` on `linux/*.sh` — same checks
  `.pre-commit-config.yaml` and `ci.yml` run.
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

> Concrete realization of the **GitHub layer** (`claude/rules/github.md`) for this repo:
> scopes = `zsh, zellij, git, nvim, macos, theme`; version scheme = SemVer; branches =
> `dev` (long-lived) → `main` (protected). The layer is baseline; the rules below win here and
> are complete on their own.

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
3. **Body** (wrap at 72 chars): explain *what* and *why*, never *how* — the diff
   shows how. Omit only for trivial, self-evident changes.
4. **Trailers** (optional): add a `Co-authored-by: Name <email>` line for each
   human contributor, one blank line before the footer block. Do not add AI or
   assistant attribution.

Scope each commit to one logical change — prefer several focused commits over one
sweeping commit. Propose the split and messages before committing.

## Local tooling (shift-left)

> Concrete realization of the **GitHub layer**'s Local tooling section
> (`claude/rules/github.md`) for this repo — same shift-left-CI idea, this repo's
> actual tools.

`.pre-commit-config.yaml` mirrors what CI enforces, run locally before push
instead of after:
- zsh syntax (`zsh -n`, same files `ci.yml` checks)
- `shellcheck` on `linux/*.sh`
- `actionlint` on `.github/workflows/*.yml`
- auto-rebase if `dev` has moved (`sync-dev.yml` rewrites it after every
  merge, which routinely makes a plain push get rejected)
- `.envrc.local.example` never picks up a real credential and stays in
  sync with `.envrc.local`

Installed automatically by `macos/deploy.zsh`'s `install_pre_commit_hooks`
step; run `pre-commit run --all-files` to check everything at once.

Two more tools worth reaching for by hand, not wired into any hook:
- `git cliff --bump` — preview the exact version/changelog `release-prepare.yml`
  would compute, with zero side effects, before actually triggering it.
- `act` — runs the GitHub Actions workflows themselves locally (via Docker),
  for testing workflow changes without pushing and waiting on real CI.

### Credentials: `.envrc` / `.envrc.local`

Concrete realization of Security By Default: routine `gh` usage in this repo
never has admin rights to lose.

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

> Concrete realization of the **GitHub layer**'s Branch & PR model
> (`claude/rules/github.md`) for this repo: long-lived branch = `dev`,
> protected branch = `main`, version scheme = SemVer. The layer is baseline;
> the rules below win here and are complete on their own.

Branching model: **long-lived `dev` + protected `main`**, squash-merged.

1. All work happens on `dev` — commit freely and messily; WIP commits don't need
   to follow the commit style (they get squashed away).
2. **Scope each PR to one logical change.** Under squash-merge one PR becomes one
   commit on `main`, so a focused PR yields a clean, atomic, revertable commit.
   Never bundle unrelated changes into a single PR just to save a round trip.
3. When a change is ready and tested, open a PR `dev` → `main`. CI must pass, then
   **squash-merge**. The PR title becomes the `main` commit message, so title the
   PR as a Conventional Commit (`type(scope): subject`).
4. After the merge, reset `dev` onto `main` so histories don't drift:
   `git switch dev && git reset --hard origin/main && git push --force-with-lease origin dev`
5. `main` stays releasable. To cut `vX.Y.Z` ([SemVer](https://semver.org)),
   git-cliff builds `CHANGELOG.md` from the Conventional Commits:
   - On `dev`: `git cliff --tag vX.Y.Z -o CHANGELOG.md`, commit as
     `chore(release): vX.Y.Z`, PR, squash-merge.
   - Tag it: `git tag -a vX.Y.Z -m vX.Y.Z && git push origin vX.Y.Z`.
   - Publish notes from the same source:
     `gh release create vX.Y.Z --notes-file <(git cliff --tag vX.Y.Z --latest --strip all)`.

`main` is never committed to directly (except one-time bootstraps). Merge method
is **squash only**; rebase-merge stays disabled and is a deliberate, temporary
exception used only to land a series of already-clean commits atomically.
