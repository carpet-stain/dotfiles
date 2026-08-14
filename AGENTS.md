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

README states the XDG principle; these are the entries that must stay in
`$HOME` despite it:

| Path                                         | Reason                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.zshenv`                                    | zsh's fixed entry point — always read from `$HOME`                                                                                                                                                                                                                                                                                                                                                                                                  |
| `.ssh/`                                      | Symlink → `~/.config/ssh/`; config tracked in `ssh/config`, keys gitignored                                                                                                                                                                                                                                                                                                                                                                         |
| `.claude/`                                   | Claude Code home: config, agent config (rules/agents/skills, symlinked from `claude/`), daemon, telemetry, and auth state. No `CLAUDE_CONFIG_DIR` relocation — Claude Code's daemon/telemetry/auth subsystems hardcode or fail to inherit it in spawned subprocesses (#134, upstream, as of 2.1.197), so relocating only the CLI's config produced a split state, not full XDG compliance. `~/.claude` is simpler and honest about actual behavior. |
| `.vscode-oss/`, `.vscode-oss-shared/`        | Claude Code desktop app data — no XDG support                                                                                                                                                                                                                                                                                                                                                                                                       |
| `.CFUserTextEncoding`, `.DS_Store`, `.Trash` | macOS system — not configurable                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `.zsh_sessions/`, `.bash_sessions/`          | Terminal.app session restore — suppressed via `SHELL_SESSIONS_DISABLE=1`                                                                                                                                                                                                                                                                                                                                                                            |
| `.terminfo/`                                 | ncurses' default search path covers `~/.terminfo` but not `$XDG_DATA_HOME`; `linux/deploy.sh` compiles Ghostty's `xterm-ghostty` entry here so it resolves in any shell (bash, zsh, sudo, cron) without `$TERMINFO` being exported                                                                                                                                                                                                                  |

## Structure & conventions

- `zsh/.zshenv` — sourced on every shell: env vars, PATH, tool config. No output,
  no tty assumptions.
- `zsh/.zshrc` — interactive only. Acts as a table of contents that sources
  `rc.d/` modules in dependency order.
- `zsh/rc.d/` — one concern per file (options, widgets, keybindings, aliases,
  completions, fzf-tab, powerlevel10k).
- `zsh/env.d/` — sourced always (e.g. `ls_colors.zsh`).
- `zsh/fpath/` — custom zle widgets and completions, autoloaded.
- `theme/` — Catppuccin submodules per tool (bat, delta, eza, fzf), each
  carrying both Mocha/Latte flavours selected by `THEME_MODE` (see
  `zsh/.zshenv` and ADR-0034). Ghostty uses its built-in
  `catppuccin-latte`/`catppuccin-mocha` themes (no submodule), switched live
  by macOS appearance via `light:...,dark:...` in `ghostty/config`.
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
- `macos/deploy.zsh` — macOS bootstrap; the deploy steps live in
  [README's Installation section](README.md#installation). Beyond those, it
  syncs theme submodules and enables git background maintenance.
- `linux/deploy.sh` — Debian bootstrap: same shape as `macos/deploy.zsh` but
  bash, apt (`linux/Aptfile`) instead of Homebrew, and GitHub release
  binaries for tools too old/missing in Debian's repos (neovim, git-delta,
  zellij, eza). Both scripts hand-maintain their own directory/runner
  logic — no shared lib between them; when one changes, check the other.
- Both deploy scripts run every step through a `required()`/`optional()`
  wrapper: critical steps (dirs, config symlinks) abort loud on failure;
  best-effort steps (a specific Brewfile package, the headless nvim bootstrap)
  log and continue. A third runner, `stream()`, carries `required()`'s
  contract for long steps (`brew bundle` and the Homebrew installer on
  macOS, apt and the neovim extract on Linux) where command substitution's
  buffering leaves the terminal silent for minutes: it streams output live
  and tees to a logfile so a failure leaves something behind. The two
  implementations catch a failing pipeline differently — zsh checks
  `$pipestatus[1]` explicitly, bash relies on the script's top-level
  `set -euo pipefail` — so changing one means checking the other.
- **`optional()` suspends errexit** (`if $(...); then`), which makes any
  "did it work?" side effect written after it unreliable. `import_deja_history`
  (in both deploy scripts) is where that bites: it passes `--file`
  explicitly, because falling back to deja's default `~/.zsh_history` (which
  this repo's `HISTFILE` relocation leaves nonexistent) would fail silently
  and still write the marker; and it gates on a marker file it alone owns,
  not on the db's existence — `deja import` is not idempotent (re-importing
  doubles row count), and the daemon `download_gitstatusd` starts creates an
  empty db before the import step runs, so an existence check would skip
  forever.
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

Don't push interactive aliases (`cat→bat`, `ls→eza`, `diff→delta`) into
agent-visible init: they live in `zsh/rc.d/aliases.zsh` (interactive-only),
and that split is the enforcement — agents get plain tools by construction.
This note exists so nobody "fixes" that by promoting the aliases to
`.zshenv`.

## Documentation: one home per fact, everything else points

> Concrete realization of **documentation.md** (`claude/rules/universal/documentation.md`) for this
> repo — the universal rule owns the home-per-fact taxonomy (which artifact owns which fact); this
> section only binds the repo-specific slots.

The universal rule's ownership table applies as-is. This repo's binding: **ADRs live in `docs/adr/`**
— the "ADR" row's concrete location, template, and numbering (below).

### ADRs (`docs/adr/`)

An Architecture Decision Record captures one significant decision: what we chose,
what we considered and rejected, and why. Write one when a decision is
architecturally significant, cross-cutting, long-lived, or expensive to reverse —
the branching model, the rules-tree load-all-then-gate design, adopting rulesets
over classic branch protection. Don't write one for a small, local,
easily-reversed choice; that's a PR description or a code comment, not an ADR.

See [`docs/adr/README.md`](docs/adr/README.md) for how to create one (adr-tools,
template, numbering, superseding).

## Verifying changes

This repo has no test suite or architectural layers to test against — Testing
By Layer's underlying idea (different kinds of behavior need different kinds
of proof) still applies, just mapped onto kinds of _changes_ rather than
architectural layers:

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
`just lint` (what you run) and `ci.yml`'s `lint` job call it, so CI and local
share one entry point and can't drift from each other.

Installed automatically by `macos/deploy.zsh`'s `install_lefthook_hooks`
step; run `just lint` to check everything at once.

### Linters/formatters by file type

The tools install via `macos/Brewfile.dev` and are mirrored by nvim's
`conform`/`nvim-lint` (not a second Mason-managed copy). Worth calling out
beyond what `lefthook.yml` shows: zsh has no formatter, `zsh -n` is
syntax-check only; shellcheck excludes zsh (false positives); markdownlint
and prettier skip `CHANGELOG.md` (git-cliff generated); json (3 files),
kdl, and js (one file) are deliberately unstyled — not enough surface to
justify a tool. `editorconfig-checker` is the catch-all closing that gap: it
enforces `.editorconfig`'s trailing-whitespace / final-newline / line-ending
rules on the files no dedicated formatter touches (zsh, `git/config`,
`ssh/config`, plain rc files), with indent checks off (`--disable-indentation`)
— those false-positive on prose, terminfo, `.gitmodules`, and required `<<-`
heredoc tabs, so indentation stays each language formatter's job.
`comment-concision` (`scripts/check-comment-concision.sh`, ADR-0044,
superseding ADR-0031's advisory nudge) blocks on a comment block over
`design-principles.md`'s signpost cap attached to one declaration. File
headers and ASCII section banners are out of scope — neither carries a why
to relocate.

Two more advisory checks run at **pre-push**, not pre-commit, so they see
the whole branch rather than one commit at a time (`git diff --name-only
origin/main...HEAD`): `deploy-pair-coupling`
(`scripts/check-deploy-pair.sh`) flags a branch that touches
`macos/deploy.zsh` without `linux/deploy.sh` or vice versa; `governance-propagation`
(`scripts/check-governance-propagation.sh`) flags a branch that touches a
governance surface (CI workflows, `lefthook.yml`, `justfile`, `cliff.toml`,
root lint configs) as a reminder to evaluate propagating the change to
`carpet-stain/project-starter-template` (#493). Both always exit 0, same
discipline as `comment-concision`. Pre-push-only means neither has a CI/PR
presence — no server-side check exists for either, so `git push --no-verify`
or a machine without lefthook installed silently skips them; accepted
because this is a solo repo whose only pusher runs on lefthook-provisioned
machines, and whole-branch three-dot diffing can't be computed cleanly
under CI's shallow `--all-files` checkout.

A few more tools worth reaching for by hand, not wired into any hook:

- `just format` — `prettier --write` over the repo's tracked markdown: the fix
  side of the `md-format` check. Manual, deliberately not a hook — `just lint`
  and CI run `prettier --check`, and `--write` always exits 0, so hooking it
  would make CI stop gating format (#406).

- `just cliff-preview` (wraps `git cliff --bump`) — preview the exact
  version/changelog `release-prepare.yml` would compute, zero side effects.
  Network-dependent by default (resolves PR links via `cliff.toml`'s
  `[remote.github]`, using `GITHUB_TOKEN` — see "Credentials" below); pass
  `--offline` (as `just cliff-preview --offline`) to skip that.
- `act` — runs the GitHub Actions workflows themselves locally (via Docker),
  for testing workflow changes without pushing and waiting on real CI. Needs
  a Docker socket, which macOS gets from Colima, not Docker Desktop — a
  headless, license-free VM that stays down unless something's using it.
  `COLIMA_HOME` relocates the whole tree at once (config, VM disk, sockets,
  logs): Lima's maintainers deliberately don't split those, so
  `XDG_CONFIG_HOME`'s narrower support is the wrong lever. No `LIMA_HOME` —
  Colima nests Lima's home at `$COLIMA_HOME/_lima` itself. Run `just act <args>` (wraps
  `scripts/act-run.sh`) rather than `act` directly: it starts Colima on demand, runs act, and
  stops Colima again only if it was the one that started it, so repeated
  runs don't re-pay the VM boot. `colima stop` tears it down explicitly when
  you're done. `actrc` (repo root, symlinked to `$XDG_CONFIG_HOME/act/actrc`
  by `deploy.zsh`) pins the runner image so act doesn't pull its own
  multi-GB default. Linux (`linux/deploy.sh`) has no Colima — its disposable
  OrbStack VMs are ephemeral dev environments, not a fit for nested
  virtualization just to run act, so this is macOS-only.
- `scripts/bootstrap-branch-protection.sh` — idempotent branch-protection
  ruleset bootstrap. Needs Administration scope no routine credential
  carries — run under infra's admin path (`with-infra-secrets.sh
--gh-admin`, infra ADR-0013; see "Credentials" below). Not wired into CI;
  run manually once a repo's checks are set up.

### Credentials: `.envrc` / `.envrc.local`

Concrete realization of three files: the credential-scoping _principle_ in
**git.md** (`claude/rules/tools/git.md`), its GitHub-specific instance in
**github.md** (`claude/rules/platform/github.md`) — routine `gh` usage in
this repo never has admin rights to lose — and Security By Default's rule
(`claude/rules/universal/engineering-practices.md`) that secrets live in
an environment file, gitignored, never hardcoded.

Routine `gh` auth is the vended token (ADR-0041, superseding ADR-0007's
per-repo PATs): `.envrc` maps `GH_TOKEN` from `GH_VENDED_TOKEN` (fetched
below), so day-to-day work rides a rotating ~1h credential with no
Administration and a covered repo needs no hand-minted PAT. Resolution
order in `.envrc`: a non-empty `GH_TOKEN` from `.envrc.local` wins
(escape hatch); else the vended token; else the sentinel
`vended-unavailable-see-453` — unconditional and last, so gh fails
closed with a visible 401 instead of silently reaching gh's keyring
credential (the #160 guarantee; the keyring's dev PAT covers infra, which
the vended grant deliberately excludes). A 401 naming the sentinel means
the vended path is down — see the fetch error at shell entry.

Escape hatch: `.envrc.local` (gitignored — never commit a real token)
keeps an empty `export GH_TOKEN=` line; `.envrc.local.example` is the
tracked template (every export line in it must stay empty; a pre-commit
hook enforces both that and that the template hasn't drifted from
`.envrc.local`'s structure). If the vended path is down for long, mint a
fresh fine-grained PAT (Contents/Issues/Pull requests/Actions read-write,
no Administration, ~2 min) and fill the line. The pre-cutover PATs are
revoked — rollback is deliberate, not "paste the old one back".

Expiry: the vended token is fetched once at shell entry and lives ~1h, so
a long-lived shell can outlive it and start 401ing. Remedy: `direnv
reload` (interactive) or a new shell (agents — `.zshenv`'s eager `direnv
export` re-fetches). Accepted exposure; no auto-refresh wrapper.

Elevation: `env -u GH_TOKEN -u GITHUB_TOKEN gh ...` drops to gh's keyring
credential — since infra#151 that's the fleet dev PAT (no Administration),
not an admin session; admin operations ride infra's Keychain-gated
`with-infra-secrets.sh --gh-admin` (infra ADR-0013). Both vars must drop:
`.envrc` aliases `GITHUB_TOKEN` to the resolved `GH_TOKEN` (for
`git-cliff`, below), so dropping `GH_TOKEN` alone leaves the identical
token behind in `GITHUB_TOKEN` — a no-op (#213, whose "gh prefers
`GITHUB_TOKEN`" reasoning was wrong; gh takes `GH_TOKEN` first. The rule
holds, the mechanism is value identity — ADR-0041). Don't "fix" this by
dropping the alias — that just breaks `git-cliff`'s token.

The fail-closed guarantee needs `GH_TOKEN` in env — direnv only fires for
interactive shells, so non-interactive ones (scripts, cron, an agent's
tool shell) used to fall back to gh's keyring session instead (#160).
`zsh/.zshenv` runs `direnv export` eagerly for every shell to fix that.

`git-cliff` reads its GitHub token from a differently-named env var
(`GITHUB_TOKEN`, not `GH_TOKEN`) — `.envrc` aliases `GITHUB_TOKEN` to the
resolved `GH_TOKEN` automatically (no second credential to manage), so it
inherits the sentinel too: a git-cliff 401 while the vended path is down is
intended, not a git-cliff bug (`--offline` skips the lookups); see
`claude/rules/platform/github.md`'s "Changelog PR links" section.

#### Vended cross-repo token (AWS SSM)

The source of routine `GH_TOKEN` (above): the sibling repo
`carpet-stain/infra` vends a rotating, narrowly-scoped GitHub token (write on
the managed repos with a live consumer, no Administration — the exact grant
list lives in infra's `vend-token.yml`) into SSM Parameter Store at
`/runtime/vended-token`, re-minted every 5 min. A local shell reads it without
ever touching the App's raw key — the sanctioned cross-repo/agent credential.
Design and role matrix live in infra's ADR-0010 (superseding the Bitwarden
story in ADR-0008/0009); this only binds the local setup (#377, store swapped
by infra#125).

Mechanism: each repo's `.envrc` runs `aws-vended-token`
(`scripts/aws-vended-token.sh`) to fetch the token fresh, check its
`expires_at`, and export `GH_VENDED_TOKEN` — failing loud at shell entry if
it's stale or missing rather than surfacing a 401 later. The script reads the
`infra-local-read` IAM user's access key from the macOS login Keychain at call
time, for that process only — no ambient `AWS_*` export (those names stay free
for other tools, e.g. infra's local tofu R2 backend). That user is
runtime-tier-only: by construction it cannot decrypt anything under
`/infra/*` (infra's `iam/main.tf`). macOS only (no consumer on the
payload-only Linux target, per ADR-0006).

One-time setup — create an access key for `infra-local-read` (AWS console, as
root: IAM → Users → infra-local-read → Security credentials → Create access
key, use case CLI), then store it (`-A` allows silent reads, since the vended
path is routine, not elevated; contrast infra's `infra-aws-local-apply`/
`infra-aws-bootstrap` items, added _without_ `-A` so their crown-jewel reads
stay prompt-gated):

```sh
security add-generic-password -s infra-aws-local-read -a <ACCESS_KEY_ID> -A -U -w
# prompts for the value — paste the secret access key,
# keeping it out of shell history
```

`audit-keychain-gate` (`scripts/audit-keychain-gate.sh`, on PATH from the
deploy) verifies those two elevated items still prompt on every read — the
gate one "Always Allow" click silently disables (found live 2026-08-09,
infra#167). It lives here because the items are this machine's login-Keychain
state; when to run it is infra's periodic audit (its `docs/BOOTSTRAP.md`).

#### OpenRouter API key (aichat)

The Alt-a floating aichat pane (#511) resolves `OPENROUTER_API_KEY` in
`scripts/aichat-pane.sh`: an already-set env var wins (escape hatch); else
the login Keychain item `openrouter-api-key`, read at pane launch for that
process only. The item is added with `-A` deliberately — routine tier on a
personal machine, same trust class as `infra-aws-local-read` above, not a
prompt-gated crown jewel. Without it the pane just warns and closes on a
keypress. One-time setup (mint the key at openrouter.ai/settings/keys):

```sh
security add-generic-password -s openrouter-api-key -a openrouter -A -U -w
# prompts for the value — paste the API key, keeping it out of shell history
```

Residency is pending infra#170's secrets-residency ADR; if it routes LLM
keys through SSM, the migration is a swap of the Keychain read in the
launcher. macOS-only — Linux gets neither aichat nor a Keychain.

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
   on conflict rather than pushing a stale commit). Finalizing is also the
   handoff: rewrite the PR body to stand alone per git.md's Branch & PR
   model, step 5. PR links in the
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
