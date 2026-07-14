# 1. XDG discipline — only .zshenv lives in $HOME

Date: 2026-07-04

## Status

Accepted

## Context

This repo's first commit (ecd45e77, 2026-07-04) shipped a strict-XDG layout.
README states the absolutist stance: "I am an absolutist about the XDG Base
Directory Specification. My `$HOME` is clean. With the exception of a single
`.zshenv` entry point, every configuration, cache, and state file is forced into
`~/.config`, `~/.cache`, or `~/.local/share` — even for tools like Homebrew,
`wget`, and `less` that don't support it natively." (README.md:13).

`.zshenv` is the one unavoidable `$HOME` file: zsh's fixed entry point, always
read from `$HOME`. It bootstraps everything else — resolves `ZDOTDIR` from its
own path so the rest of the config lives outside `$HOME`, then sets
`XDG_{CONFIG,CACHE,DATA,STATE}_HOME` and overrides each tool's default path into
those dirs (`HISTFILE`, `LESSHISTFILE`, `HTOPRC`, `RIPGREP_CONFIG_PATH`,
`TEALDEER_CONFIG_DIR`, `TERMINFO`, `TMUX_TMPDIR`, `_ZO_DATA_DIR`, plus
Homebrew's cache/logs/temp). `macos/deploy.zsh` then symlinks every tracked
config into `$XDG_CONFIG_HOME` (bat, git, htop, nvim, ripgrep, …), so the
deployed state matches the stated discipline.

The forcing problem: many tools default to a dotfile or dotdir in `$HOME`, and
some don't read any XDG variable natively. Left alone, `$HOME` accumulates
per-tool clutter and there's no single tree that is "the config." The goal is
one canonical config tree under `$XDG_CONFIG_HOME` with a `$HOME` that stays
clean, and a documented, finite set of exceptions for the files that genuinely
can't move.

(provenance: partial — first-commit intent reconstructed; the exceptions table
and the falsifiability framing are later/inferred.)

## Decision

Force every configuration, cache, and state file under
`$XDG_{CONFIG,CACHE,DATA,STATE}_HOME`. `.zshenv` is the sole intentional `$HOME`
resident — it's zsh's fixed entry point and can't be relocated — and it
bootstraps the rest by exporting the XDG base dirs and overriding each tool's
default path into them. Tools that don't honor XDG natively get an explicit
env-var override in `.zshenv`; deploy symlinks the tracked configs into
`$XDG_CONFIG_HOME`. Anything that genuinely can't be relocated is a named,
documented exception rather than a silent leak — the exceptions are enumerated
(the exceptions table is a later refinement; at the first commit AGENTS.md said
only "only `.zshenv` lives there") (anachronism), and a clean `$HOME` is kept
falsifiable by that list: a `$HOME` file not on it is a defect to fix (inferred
— #134 frames a leak as an XDG-discipline violation but doesn't state this
falsifiability framing).

## Alternatives considered

- **Plain `$HOME` dotfiles / no XDG** — the default most dotfiles ship.
  Rejected: leaves `$HOME` cluttered with per-tool dotfiles and dotdirs, and no
  single tree is "the config."
- **A dotfile manager (chezmoi, GNU stow) to corral `$HOME` files** — rejected.
  Forcing tools into XDG dirs at the source means there's little `$HOME` state
  left to corral, so a manager solves a problem this approach mostly removes
  (inferred — the "unnecessary" link isn't stated; see the Homebrew-first /
  no-dotfile-framework ADR for the no-framework stance).
- **Relocate everything, including tools that hardcode `$HOME`** — rejected:
  some paths can't move. `.zshenv` is zsh's hardcoded entry point, and Claude
  Code's daemon/telemetry/auth write to `~/.claude` regardless of
  `CLAUDE_CONFIG_DIR` (#134). Fighting hardcoded paths yields split state, not
  compliance.
- **Export env vars like `$TERMINFO` globally to force relocation everywhere** —
  rejected in favor of documented exceptions. ncurses' default search path
  covers `~/.terminfo` but not `$XDG_DATA_HOME`; rather than export `$TERMINFO`
  into every shell (bash, zsh, sudo, cron), the entry is compiled to a
  documented `$HOME` exception so it resolves without a global export.

## Consequences

`$HOME` stays clean and inspectable: one canonical config tree under
`$XDG_CONFIG_HOME`, and the exceptions list (a later addition) makes any stray
`$HOME` file stand out (inferred, per Context).

Each new tool needs its default path checked and, if it ignores XDG, an explicit
override added in `.zshenv` — ongoing per-tool work (inferred). If a tool later
gains native XDG support, its override can be dropped (inferred).

Amendment (58104816, 2026-07-13; #134, #209): Claude Code's
daemon/telemetry/auth subsystems hardcode `~/.claude` and don't inherit
`CLAUDE_CONFIG_DIR` in spawned subprocesses (upstream, as of 2.1.197), so
relocating its config to `$XDG_CONFIG_HOME/claude` only ever half-worked — CLI
config at the XDG path, daemon/telemetry/auth state at `~/.claude` regardless.
The `CLAUDE_CONFIG_DIR` relocation was dropped and `~/.claude` adopted as a
documented XDG exception: honest about actual behavior, no split state to reason
about. This is #134's "accept & document" path (#209). It refines the exceptions
set; it does not supersede the XDG discipline itself.
