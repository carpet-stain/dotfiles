# 2. Homebrew-first package management, no dotfile framework except Powerlevel10k

Date: 2026-07-04

## Status

Accepted

## Context

A fresh machine must reach a working setup by cloning the repo and running one
deploy script (README "Portable, quick to install"; AGENTS.md @ ecd45e77). That
needs two things: a package manifest and a way to place configs. The primary
target is macOS on Apple Silicon (Homebrew); Debian is a secondary target (apt)
(README). The repo also holds a strict-XDG stance and "no bloat — every setting
earns its place" (AGENTS.md @ ecd45e77), which sits uneasily with a dotfile
manager that owns its own state/templating layer or a zsh framework that pulls
in config the author didn't write. The decision, made at repo inception
(ecd45e77, 2026-07-04): how to install packages and place configs without a
framework taking over.

(provenance: partial — the philosophy "No dotfile manager or framework —
Powerlevel10k is the sole exception" is sourced verbatim from AGENTS.md @
ecd45e77, but the specific tools those categories cover, chezmoi/stow/
oh-my-zsh, are named nowhere in the repo; their per-tool rejection reasoning is
inferred from that stance, not recorded.)

## Decision

Declarative package manifest plus plain-symlink deploy. macOS: `macos/Brewfile`
(Homebrew bundle) is the manifest; Debian: `linux/Aptfile` (apt) is the
equivalent. `macos/deploy.zsh` (and `linux/deploy.sh`) install the manifest,
then `zf_ln -s` each config into `$XDG_CONFIG_HOME` — no templating, no
manager-owned state. No dotfile manager or zsh framework; Powerlevel10k is the
sole adopted framework, carried both as a Homebrew package (`macos/Brewfile`)
and a git submodule (`.gitmodules`). When Homebrew lacks a package it becomes a
git submodule (AGENTS.md @ ecd45e77; README).

## Alternatives considered

- **Dotfile manager (e.g. chezmoi)** — rejected: adds a templating +
  manager-owned-state layer over configs, against the strict-XDG / no-bloat
  stance (AGENTS.md @ ecd45e77) and the plain-symlink deploy that already covers
  placement (`zf_ln -s` in `macos/deploy.zsh`). (inferred — chezmoi is not named
  in any source; "No dotfile manager" is the sourced category.)
- **Symlink-farm manager (e.g. GNU stow)** — rejected: only automates the
  symlinking the deploy script already does by hand, and the script does more
  than symlink (creates XDG dirs, installs Homebrew/Brewfile, syncs submodules,
  builds terminfo/caches — `macos/deploy.zsh`), so a farm manager would replace
  the smallest part. (inferred — stow is not named in any source.)
- **zsh framework (e.g. oh-my-zsh)** — rejected: bundles a large config surface
  the author didn't write, against "No bloat — every setting earns its place"
  (AGENTS.md @ ecd45e77). The repo instead assembles zsh from
  individually-pinned plugins and sources `rc.d/` modules directly (README
  Features). (The "No framework" category is sourced; oh-my-zsh as the specific
  named tool is inferred.)

## Consequences

Install stays a clone + one deploy run (README). Configs are plain files a
symlink exposes verbatim — no manager or template layer to learn, diff, or
debug. Adding a tool is a one-line Brewfile/Aptfile edit plus a symlink; the
manifest is the single readable inventory. Cost: the two deploy scripts
hand-maintain their own symlink/dir logic with no shared lib, so a config move
must be reconciled in both (AGENTS.md "when a change spans files, update all").
Powerlevel10k is the deliberate exception — a full prompt framework, carried as
both a Homebrew package and a git submodule; the deploy runs a
`download_gitstatusd` bootstrap step for it (`macos/deploy.zsh`). Revisit if the
symlink loop outgrows hand-rolling, or if manifest drift between Brewfile and
Aptfile becomes costly enough to want a single source (inferred design judgment,
not a recorded consequence).
