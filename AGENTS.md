# AGENTS.md

Guidance for AI assistants working in this repo (repo-specific).
Vendor-neutral; the root `CLAUDE.md` is a gitignored symlink to this file.

> **Note:** this repo also has a `claude/` directory unrelated to the root
> `CLAUDE.md` symlink above. It's the global agent-config tree (mostly the
> `claude/global/` submodule, plus a few files that stay local to this repo),
> deployed to `~/.claude/{rules,agents,skills}`, where Claude Code
> auto-discovers and loads them — see `claude/README.md`.

## Precedence: this repo's own docs win over the generic files

If the agent supplies the generic global files (universal philosophy, Go, GitHub mechanics),
this repo's own documents are **authoritative** where they overlap — treat any generic file
as baseline and prefer this file and the sections below on conflict. The universal philosophy
is not _overridden_; this repo illustrates how it is realized. A contributor without any
of the global files loses nothing — this guide is the full story.

## What this is

Personal macOS dotfiles (Ghostty + Zellij + zsh + Neovim, Debian secondary
target) — see [README.md](README.md) for the full pitch and stack.

## Philosophy

See [README.md](README.md#philosophy--stack) for the full list. Each point
there is this repo's concrete realization of a universal design principle:
Modern Replacements → Small, Composable Tools; Zero Home Presence (XDG) →
Configuration Is Code, Not Ambient State; no speculative/dead config →
Simplicity First / Refactoring.

### XDG exceptions

The entries that must stay in `$HOME` despite the XDG principle, and why
each one: [docs/xdg-exceptions.md](docs/xdg-exceptions.md). Check it before
adding anything to `$HOME` or "fixing" an entry already listed there.

## Structure & conventions

- `zsh/.zshenv` — sourced on every shell: env vars, PATH, tool config. No output,
  no tty assumptions.
- `zsh/.zshrc` — interactive only. Acts as a table of contents that sources
  `rc.d/` modules in dependency order.
- `zsh/rc.d/` — one concern per file (options, widgets, keybindings, aliases,
  completions, fzf-tab, powerlevel10k).
- `zsh/env.d/` — sourced always (e.g. `ls_colors.zsh`).
- `zsh/fpath/` — custom zle widgets and completions, autoloaded.
- `theme/` — Catppuccin submodules per tool (bat, delta, eza, fzf), both
  Mocha/Latte flavours selected by `THEME_MODE` (`zsh/.zshenv`, ADR-0034).
  Ghostty uses its built-in catppuccin themes (no submodule), switched live
  by macOS appearance in `ghostty/config`.
- `zellij/` — `config.kdl` (keybinds, kitty-keyboard-protocol disabled for nvim
  compat), `layouts/default.kdl` (zjstatus status bar), `themes/catppuccin.kdl`
  (vendored, not a submodule — same rationale as `theme/`).
- `nvim/` — LazyVim on `lazy.nvim`. Official language extras are imported in
  `lua/config/lazy.lua` (`lazyvim.plugins.extras.lang.*`); everything else
  custom goes in `lua/plugins/*.lua`, one file per concern. Mason's
  `ensure_installed` must list LSP/tool names explicitly — the indirect
  auto-install via `nvim-lspconfig`'s `servers` table doesn't reliably fire
  during a headless `deploy.zsh` run. `lazy-lock.json` is tracked and
  symlinked (LazyVim's own recommended practice).
- `macos/deploy.zsh` / `linux/deploy.sh` — the two bootstrap scripts; steps
  and platform differences live in
  [README's Installation section](README.md#installation). No shared lib
  between them; when one changes, check the other.
- Both deploy scripts run every step through `required()`/`optional()`/
  `stream()` runners: abort-loud, log-and-continue, and `required()`'s
  contract with live tee'd output for long steps that command
  substitution's buffering would leave silent for minutes. The two
  implementations catch a failing pipeline differently — zsh checks
  `$pipestatus[1]` explicitly, bash relies on top-level
  `set -euo pipefail` — so changing one means checking the other.
- **`optional()` suspends errexit** (`if $(...); then`), making any "did it
  work?" side effect after it unreliable. `import_deja_history` (both
  scripts) is where that bites: it passes `--file` explicitly (deja's
  default `~/.zsh_history` doesn't exist under this repo's `HISTFILE`
  relocation — the fallback would fail silently yet still write the
  marker), and it gates on a marker file it alone owns, not the db's
  existence — `deja import` isn't idempotent, and the gitstatusd daemon
  creates an empty db before the import runs, so an existence check would
  skip forever.
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
  provenance: `git blame` → `git show <sha>` → PR comments → issue.
  Rebase-merge and draft-PR journaling keep that chain intact end to end
  here, so the traversal is worth it.
- Concrete realization of Propose Before Implementing for this repo: editing
  `claude/rules/*.md`, `README.md`'s voice, or this file itself is opinion/judgment
  content — discuss before writing or committing. zsh/nvim/tool-config tweaks are
  mechanical — proceed and report.

## Agent shell tool preference

Prefer `rg`/`fd` over `grep`/`find` in Bash: faster, and gitignore-aware by
default — `.rgignore` (repo root) is half of `#437`'s search-noise fix, the
other half is `permissions.deny` in `claude/settings.json`. Keep output
plain: `--no-pager`, `--color=never`, no TUI tools (`viddy`), no pagers
(`delta` as a pager), no fuzzy resolution (`zoxide`) — decorated output is
ANSI token waste and fuzzy jumps are nondeterminism. `zsh/.zshenv`'s
`RIPGREP_CONFIG_PATH` (`ripgreprc`) is tuned for interactive use — colors,
hyperlinks — and applies to every shell including an agent's, so pass
`--color=never` explicitly rather than assuming the default is plain.

Don't promote interactive aliases (`cat→bat`, `ls→eza`, `diff→delta`) out
of `zsh/rc.d/aliases.zsh` (interactive-only) into `.zshenv` — that split is
the enforcement: agents get plain tools by construction.

## Documentation: one home per fact, everything else points

> Concrete realization of **documentation.md** (`claude/rules/universal/documentation.md`) for this
> repo — the universal rule owns the home-per-fact taxonomy (which artifact owns which fact); this
> section only binds the repo-specific slots.

The universal rule's ownership table applies as-is. This repo's binding: **ADRs live in `docs/adr/`**
— the "ADR" row's concrete location, template, and numbering (below).

### ADRs (`docs/adr/`)

Write one for a decision that's architecturally significant, cross-cutting,
long-lived, or expensive to reverse — what we chose, what we considered and
rejected, and why. A small, easily-reversed choice is a PR description or a
code comment, not an ADR. See [`docs/adr/README.md`](docs/adr/README.md)
for how to create one (adr-tools, template, numbering, superseding).

## Verifying changes

No test suite or architectural layers here — Testing By Layer's idea
(different kinds of behavior need different kinds of proof) maps onto kinds
of _changes_ instead:

- **Syntax/lint/format**: `just lint` (wraps `lefthook run pre-commit
--all-files`) — see "Local tooling" below for the tool list and why it
  mirrors CI.
- **Runtime behavior for nvim plugin config**: verify via the
  `verify-nvim-config` skill — it launches the deployed config headless and
  reads back the plugin's merged module state to confirm an option took effect,
  not just that the file parses.
- **Claude Code config changes** (`claude/rules/*.md`, deploy symlinking):
  check `/memory` in a real session lists the expected rules files loaded from
  `~/.claude/rules`.
- **Deploy script changes**: re-run `deploy.zsh`/`deploy.sh` and confirm it's
  idempotent — a second run should be clean, not error or duplicate work.

## Commit style

> Concrete realization of **git.md** (`claude/rules/tools/git.md`) for this repo;
> version scheme = SemVer; branches = short-lived feature branches → `main`
> (protected). It's baseline; the rules below win here and are complete on their own.

Follow `git/committemplate` and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope): description` — imperative, lowercase subject, no trailing period,
≤50 chars where possible (hard limit 72); blank line; then a body wrapped at 72
explaining _what_ and _why_ (never _how_ — the diff shows that), omitted only
when trivial.

- **type** is enforced by `pr-guards.yml`'s `conventional commit` check (CI-only,
  no local mirror — see it for the exact list). Breaking change: `type!:` or a
  `BREAKING CHANGE:` footer.
- **scope** (optional) — a repo area: `claude, git, zsh, macos, github, ci, theme,
release, adr, nvim, linux, docs, deploy, ghostty`.
- **Trailers**: `Co-authored-by:` per human contributor; never AI/assistant
  attribution.

One logical change per commit — prefer several focused commits over one sweeping
one; propose the split and messages before committing.

## Local tooling (shift-left)

> Concrete realization of two files: the shift-left-CI-mirroring and credential-scoping
> guidance in **git.md** (`claude/rules/tools/git.md`), plus the GitHub-specific
> instances of it — `act`, GitHub Actions workflow linting — in **github.md**
> (`claude/rules/platform/github.md`).

Dev verbs live in the root `justfile` — run `just --list` for the full set.
The recipes are the canonical invocation; this section explains the _why_
behind the non-obvious ones, not the commands. Elevated-credential scripts
(below) deliberately stay out of the justfile.

`lefthook.yml` is the single source of truth for lint/format checks — both
`just lint` (what you run) and `ci.yml`'s `lint` job call it, so CI and
local share one entry point and can't drift. Hooks install via
`deploy.zsh`'s `install_lefthook_hooks` step.

### Linters/formatters by file type

`lefthook.yml` is also where each non-obvious hook's why lives, as inline
comments (`editorconfig`'s catch-all role and indent exemptions, `gitleaks`'
whole-tree scan). The tools install via `macos/Brewfile.dev` and are
mirrored by nvim's `conform`/`nvim-lint` (not a second Mason-managed copy).
What the config can't show:

- zsh has no formatter — `zsh -n` is syntax-check only, and shellcheck
  excludes zsh (false positives). json, kdl, and js are deliberately
  unstyled: not enough surface to justify a tool.
- `comment-concision` blocks on a comment block over the signpost cap
  (ADR-0044, superseding ADR-0031's advisory nudge); file headers and ASCII
  banners are out of scope.
- The pre-push jobs (`deploy-pair-coupling`, `governance-propagation`) are
  advisory — always exit 0; each script's header owns its scope and why.
  Pre-push-only means no CI/PR presence, so `--no-verify` skips them
  silently — accepted for a solo repo whose only pusher runs lefthook, since
  their whole-branch three-dot diffs can't be computed under CI's shallow
  `--all-files` checkout.

A few more tools worth reaching for by hand, not wired into any hook:

- `just format` — `prettier --write` over the repo's tracked markdown: the fix
  side of the `md-format` check. Manual, deliberately not a hook — `--write`
  always exits 0, so hooking it would make CI stop gating format (#406).
- `just cliff-preview` (wraps `git cliff --bump`) — preview the exact
  version/changelog `release-prepare.yml` would compute, zero side effects.
  Network-dependent by default (`GITHUB_TOKEN` — see "Credentials" below);
  pass `--offline` to skip that.
- `just act <args>` — run the Actions workflows locally via Docker, which
  macOS gets from Colima (a headless, license-free VM), not Docker Desktop.
  `scripts/act-run.sh`'s header owns the mechanics and the
  `COLIMA_HOME`/`actrc` choices; `colima stop` tears the VM down when
  you're done. macOS-only — Linux's disposable OrbStack VMs aren't a fit
  for nested virtualization just to run act.
- `scripts/bootstrap-branch-protection.sh` — idempotent branch-protection
  ruleset bootstrap. Needs Administration scope no routine credential
  carries — run under infra's admin path (`with-infra-secrets.sh
--gh-admin`, infra ADR-0013; see "Credentials" below). Not wired into CI;
  run manually once a repo's checks are set up.

### Credentials: `.envrc` / `.envrc.local`

Concrete realization of the credential-scoping _principle_ in **git.md**
(`claude/rules/tools/git.md`), its GitHub-specific instance in **github.md**
(`claude/rules/platform/github.md`), and Security By Default's
secrets-in-env-files rule
(`claude/rules/universal/engineering-practices.md`).

Routine `gh` auth is infra's rotating vended token with a fail-closed
sentinel floor. **ADR-0041 owns the model**;
[docs/credentials.md](docs/credentials.md) owns the operational story — the
`.envrc`/`use_github_token` wiring, the Keychain items and their one-time
setup, the OpenRouter key, and the launchd jobs riding the same
credentials. What an agent needs session to session:

- Attributed GitHub writes (a comment or review posted as the agent's own
  identity) ride `agent-gh <role> -- gh ...` (`docs/credentials.md` §
  Agent-account PATs: `agent-gh`) — fetches the role's PAT from SSM and
  asserts the login before running. The ambient `GH_TOKEN` above is the
  repo-scoped vended App token: CI/routine plumbing, never an agent's
  identity.
- A `gh` (or git-cliff) 401 naming `vended-unavailable-see-453` means the
  vended path is down — see the fetch error at shell entry. An expired
  token (~1h life) in a long-lived shell: a new shell, or `direnv reload`.
- Elevation drops both vars — `env -u GH_TOKEN -u GITHUB_TOKEN gh ...`
  (value identity: `GITHUB_TOKEN` aliases `GH_TOKEN` for `git-cliff`);
  admin rides infra's `with-infra-secrets.sh --gh-admin` (infra ADR-0013).

### Per-spike token accounting (#476)

Tokens are the spike effort currency (#475 dropped time-boxing). When
closing a spike or issue, run `just token-cost <issue-number>` **before the
branch's worktree is torn down** — it posts the per-issue rollup as a closing
comment from this machine's transcripts (`scripts/record-token-cost.sh`). "Before
the worktree is torn down" is load-bearing, not just tidy timing: a
branch named `issue-NNN`/`fix-NNN` gets attributed by that convention
(`scripts/token-attribution/parse.mjs`'s `ISSUE_BRANCH_RE`); any other branch
name still gets its tokens recorded, just keyed by the raw branch string —
`record-token-cost.sh` falls back to looking up the _current_ branch when the
issue-number lookup misses (#650). That fallback only works from the issue's
own worktree, before it's gone. Run it and don't ignore a non-zero exit — a
miss there means the rollup is gone for good, not just delayed.
This is also `groom-backlog`'s repo-specific sweep note: weigh recorded
token-cost comments as real-spend evidence when estimating similar work.

`record-token-cost.sh` is repo-agnostic (#673): dotfiles owns the one
implementation and deploys it onto PATH (`record-token-cost`, `agent-gh`'s
shape), so any checkout invokes it directly —
`record-token-cost <issue-number> [owner/repo]`, defaulting to the invoking
repo — and it comments there (`gh issue comment -R`), not on dotfiles. `just
token-cost` above is dotfiles' own convenience wrapper over the same script,
nothing more. Another repo's justfile should call the PATH tool directly
rather than copying this recipe.

## Git workflow

> Concrete realization of **git.md**'s Branch & PR model
> (`claude/rules/tools/git.md`) for this repo: short-lived feature branches,
> protected branch = `main`, version scheme = SemVer. It's baseline; the
> rules below win here and are complete on their own.

Branching model: **short-lived feature branches + protected `main`**,
rebase-merged. You own the commit that lands on `main` — GitHub doesn't
rewrite it. The `git new`/`git squash`/`git pr` scripts
(`scripts/git-*.sh`) each own their step's mechanics and why in their
headers.

1. `git new <name>` — branch off a freshly-fetched `origin/main`
   (`git-new.sh`). No required naming convention — a descriptive `<name>` is
   fine; `issue-NNN`/`fix-NNN` only buys cleaner keying in token-accounting's
   report, not a requirement (see "Per-spike token accounting" below).
   Once the first commit exists, open a **draft PR right
   away** with `git pr --draft`; journal decisions, gotchas, and
   retractions as PR comments as work proceeds — the PR is the real-time
   record.
2. Commit freely while working — WIP commits needn't follow the commit
   style; `pr-guards.yml`'s gates skip drafts. **One logical change per
   PR** — never bundle unrelated changes to save a round trip.
3. When ready and tested: `git squash` collapses the branch to exactly one
   Conventional Commit (`git-squash.sh` — why it rebases before resetting),
   then `git pr` finalizes (`git-pr-link.sh` — re-fetches, rebases, flips
   ready, force-pushes). Finalizing is the handoff: rewrite the PR body to
   stand alone. Changelog PR links resolve from GitHub's commit↔PR
   association at generation time, so no subject amend is needed. Once
   green, **rebase-merge**; the branch auto-deletes.
4. `main` stays releasable, never committed to directly (except one-time
   bootstraps); cutting a release is automated ([SemVer](https://semver.org)
   from Conventional Commits by [git-cliff](https://git-cliff.org)):
   preview with `just cliff-preview`, dispatch `gh workflow run
release-prepare.yml -f bump=auto`, then review and rebase-merge the
   `release/vX.Y.Z` PR it opens — `release-publish.yml` tags and publishes.
   The `.github/workflows/release-*.yml` comments own the mechanism and
   why; by-hand equivalent if automation is unavailable:
   `git cliff --tag vX.Y.Z -o CHANGELOG.md` → commit → tag →
   `gh release create`.

Local `main` is otherwise vestigial — every change branches off
`origin/main` directly. `git sync` (`git-sync.sh`; safe/loud under
`merge.ff=only`) refreshes it by hand when tooling or sanity wants one —
not part of the per-change flow.
