# 6. Three-tier deploy model (payload / dev-tooling / repo-meta); Linux excludes dev tooling

Date: 2026-07-09

## Status

The repo-meta tier's example list below (Decision) names the `python/`+
`git-flow/` templates, which have since moved to
[`carpet-stain/project-starter-template`](https://github.com/carpet-stain/project-starter-template)
(ADR-0028) — the tier concept and the rest of its examples are unaffected.

Superceded by [30. Redefine dev tier as the CI/lint/release toolchain only](0030-redefine-dev-tier-as-the-ci-lint-release-toolchain-only.md)

## Context

The repo deploys to two targets: macOS (the primary dev machine) and
Debian/Linux (a secondary target, mainly a disposable OrbStack VM SSH'd into —
README, `7f6e08a3`). Debian support landed with `linux/deploy.sh` on 2026-07-09
(`7f6e08a3`, v1.3.0), giving the repo a second deploy path alongside
`macos/deploy.zsh`.

Those two scripts install and symlink overlapping-but-not-identical sets. Where
they diverge, the divergence is accidental — two hand-maintained package lists
(`macos/Brewfile` vs `linux/Aptfile`) that drift, with no declared "what tier is
this" source of truth (#127). The macOS Brewfile carries the full
CI/lint/release toolchain (act, shellcheck, shfmt, taplo, yamlfmt, markdownlint,
git-cliff, lefthook, actionlint, selene, stylua, uv); the Aptfile carries none
of it. But dev tooling still leaks onto Linux: `install_apt_packages` in
`linux/deploy.sh` installs `golang-go`, `golang-src`, `gh`, and `nodejs`
unconditionally, and `link_configs` symlinks the
`git-pr-link`/`git-new`/`git-sync` scripts onto the VM (#127). Nothing gates
that leak; the split exists only as Brewfile↔Aptfile coincidence, not as intent.

The split is one structural question (#127): a disposable Linux VM should
inherit the dotfile payload (shell, editor, prompt, user CLI tools) but not the
dev toolchain used to develop _this_ repo; macOS gets both. The concrete
requirement: Linux deploys the payload tier only.

(provenance: partial — #127 open; model reconstructed from deploy-script code +
issue proposal)

## Decision

Classify everything the repo carries into three tiers:

- **Payload** — deployed everywhere (macOS + Linux): `zsh/`, `nvim/` (editor),
  `zellij/`, `ghostty/`, `theme/`, `git/config`, `ssh/`, loose rc files, and the
  user CLI tools (fd, rg, eza, bat, delta, zoxide, fzf, neovim, zellij,
  tealdeer) (#127).
- **Dev tooling** — dev machine (macOS) only, excluded on Linux: the
  CI/lint/release toolchain (act, uv, shellcheck, shfmt, taplo, yamlfmt,
  markdownlint, git-cliff, lefthook, actionlint, selene, stylua, node-for-LSPs),
  the git PR/release scripts and their `pr`/`new`/`sync` aliases, nvim's dev
  LSP/mason stack, and `golang-go`/`gh`/`nodejs` (#127).
- **Repo-meta** — deployed nowhere; exists only to develop this repo:
  `.github/`, `cliff.toml`, `lefthook.yml`, `.envrc*`, the `python/`+`git-flow/`
  templates, `AGENTS.md`/`README.md`/`CHANGELOG.md`, `scripts/`, lint configs,
  `COPYING` (#127).

The Linux target ships the payload tier only. macOS = payload + dev tooling.
Repo-meta deploys neither.

## Alternatives considered

- **Payload/tooling top-level directory split** — move payload configs under one
  dedicated dir so the deploy symlinks a single tree and the boundary is visible
  in the layout (original #127 legibility idea). Rejected as the mechanism:
  highest migration cost — every symlink target in both deploy scripts moves,
  and `nvim/lua/plugins/*` doesn't divide cleanly by directory, so it'd need
  splitting file by file. It also doesn't fix the Brewfile↔Aptfile package drift
  on its own (#127).
- **Directory-name/tag convention plus a linter check** — cheapest, but
  reactive: it flags a leak (like the `git-pr-link.sh` one) after the fact
  rather than preventing it, and the linter needs the same hand-maintained tier
  map as everything else (#127).
- **Keep the accidental Brewfile↔Aptfile divergence as the split** — the status
  quo. Rejected: it's not a decision, it's coincidence that drifts, and it's
  exactly what lets `golang-go`/`gh`/`nodejs` leak onto Linux with nothing
  stopping it (#127).
- **Leave `golang-go`/`gh`/`nodejs` on Linux** — considered a live
  classification call rather than obvious (#127). Placed in the dev tier: a
  disposable VM SSH'd into for editing doesn't need the Go toolchain, GitHub
  CLI, or Node-for-LSPs (inferred from the "dotfile payload minus dev tooling"
  driver, #127).

## Consequences

One declared answer for "what tier is this," so the Linux/macOS split stops
being Brewfile↔Aptfile luck. The named leak becomes a concrete fix target: drop
`golang-go`/`golang-src`/`gh`/`nodejs` from `install_apt_packages` and the
`git-pr-link`/`git-new`/`git-sync` symlinks from Linux's `link_configs`. A
single payload source of truth (a tier-tagged manifest, mechanism TBD) removes
the two-list drift.

Nothing enforces the tiers yet — the boundary is review-enforced convention
until a mechanism ships. The classification also surfaces cross-cutting files
split within themselves that still need per-item calls: `git/config` (payload
config vs dev-only `pr`/`new`/`sync` aliases pointing at absent `scripts/`),
`nvim/` (lean editor vs full dev LSP/mason stack on Linux), and `claude/`
(deployed identically on both today — payload or dev?) (#127).

Revisit when #127's follow-on migration epic lands: it touches layout,
Brewfile/Aptfile, both deploy scripts, and the git/nvim/claude splits. Until
then this ADR records the model, not a finished migration — #127 is an open
spike, so the tiers are ratified in principle but not yet embodied in tooling
(#127).
