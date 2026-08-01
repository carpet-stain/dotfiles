# 34. cascade over toggle single derivation for CLI theme surfaces

Date: 2026-07-31

## Status

Accepted

## Context

Every themed tool in this repo (Ghostty, Zellij, FZF, Bat, Delta, eza,
LS_COLORS, zsh-patina, powerlevel10k, Neovim) was hardcoded to Catppuccin
Mocha. There was no light option and no way to follow macOS appearance
without hand-editing half a dozen configs (#439). The design had to cover a
dozen tools with very different theming mechanisms — some read an env var
per invocation, some read a fixed config file at a fixed path, two (Ghostty,
Neovim) can genuinely query the OS/terminal live — without turning every
config into a templated, deploy-time-rendered file.

## Decision

**One env derivation drives every CLI surface; two tools follow the OS
natively instead.**

`THEME_MODE=dark|light` is derived once per shell init, in `zsh/.zshenv`,
from macOS's `AppleInterfaceStyle` (present only in dark mode — absent means
light; Linux hardcodes dark, no OS-level appearance API targeted here). Every
CLI surface below reads that single variable, each through whatever lever it
already exposes — no tool re-queries the OS itself, and no tool's own
config file is rewritten at switch time:

| Surface     | Lever                                                                | Verified how                                                                                                                                                       |
| ----------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| bat         | `BAT_THEME` env var                                                  | installed binary: env var wins over a config-file `--theme` line                                                                                                   |
| delta       | `DELTA_FEATURES` env var                                             | installed binary: env var alone activates a `[delta "catppuccin-<flavour>"]` section, no gitconfig `features` key needed                                           |
| eza         | `EZA_CONFIG_DIR` (mode-selected directory, both deployed)            | binary strings confirm `EZA_CONFIG_DIR`/`theme.yml` as the real lookup — eza has no per-invocation color-override env var                                          |
| LS_COLORS   | mode-selected pre-generated blob, sourced by `THEME_MODE`            | two `vivid generate catppuccin-<mocha\|latte>` blobs, same vivid version for parity                                                                                |
| fzf/fzf-tab | mode-selected submodule theme file; fzf-tab rides `FZF_DEFAULT_OPTS` | —                                                                                                                                                                  |
| zsh-patina  | `ZSH_PATINA_CONFIG_PATH` env var                                     | installed binary: only lever exposed (no CLI flag on `activate`/`start`); confirmed via `zsh-patina check` against a deliberately broken config at that exact path |
| p10k        | conditional palette block in `rc.d/powerlevel10k.zsh`                | —                                                                                                                                                                  |

Genuine native OS-following is reserved for **Ghostty** (`light:...,dark:...`
theme syntax) and **Neovim** (terminal background query, or `THEME_MODE`
fallback where that query doesn't survive Zellij — #440). Zellij itself is a
deliberate gap: see Consequences.

## Alternatives considered

- **A stateful toggle command** (e.g. `theme switch`) — rejected: a second
  source of truth alongside the OS setting, and it means rewriting tracked
  config at switch time instead of switching being a pure function of
  `THEME_MODE` at shell/process spawn.
- **Native background auto-detection for bat/delta** — rejected: both would
  need their own OSC-11-style terminal query, which doesn't reliably survive
  Zellij passthrough (see #440's step-0 finding), and bat's own fallback when
  that query fails isn't Catppuccin.
- **A Zellij launch wrapper** that passes `--layout` per mode — rejected,
  see Consequences: structurally dead against this repo's `attach --create`
  launch model.

## Consequences

**Zellij is a deliberate gap.** The launch is `exec zellij attach --create
default` — a persistent, resurrectable session. `attach` takes no
`--layout`, and create-time layout selection ~never fires for a returning
session, so `zellij/themes/catppuccin.kdl` and the zjstatus bar
(`zellij/layouts/default.kdl`) stay Mocha regardless of `THEME_MODE`.
Session persistence and appearance-following are in direct tension; closing
this gap is a session-model decision, not a config one — spiked later only
if the dark bar on a light terminal proves to hurt in practice.

**Amendment (2026-08-01, #506): the gap splits in two, one half closes.**
The dark-bar friction fired (#441 shipped, PR #505) and triggered the
evidence-gated spike. Findings, not speculation — verified against the
installed `zellij 0.44.3` binary and both upstream trackers:

- **`zellij/config.kdl`'s own `theme` selection is closeable now, natively.**
  Zellij 0.44.2 added CSI 2031/DSR 997 host-terminal color-scheme detection —
  `theme_dark`/`theme_light` config keys plus `set-dark-theme`/
  `set-light-theme`/`toggle-theme` actions, applied live when the _host
  terminal_ reports its palette. Ghostty implements the terminal side of
  that same protocol already (`ghostty/config`'s `light:...,dark:...`). This
  is a third genuinely-native surface, same tier as Ghostty/nvim above — no
  wrapper, no `THEME_MODE` plumbing, no toggle. Follow-up filed to adopt it.
- **The zjstatus bar — the actual reported friction — stays a gap, for a
  different reason than originally recorded.** zjstatus has no native
  Zellij-theme inheritance (open feature request, dj95/zjstatus#12); its hex
  colors are static plugin config baked in at launch. The one lever that
  could re-theme it live without a session restart,
  `zellij action start-or-reload-plugin`, is blocked by an open upstream bug
  (zellij-org/zellij#3927, #3994, #3995): reloading a plugin instance that
  was started as part of a layout — exactly this repo's setup, zjstatus
  lives inside `default_tab_template` in `layouts/default.kdl` — opens a
  duplicate pane instead of reloading in place. `default_tab_template` also
  means every open tab runs its own zjstatus instance, so a working fix
  would need to iterate every tab, not just one pane. No workaround here
  clears the no-stateful-toggle bar cleanly enough to adopt.

The original "session-model decision" framing is superseded for the config
theme (closed, natively) and narrowed for the bar (blocked on a specific,
trackable upstream bug, not a fundamental `attach --create` conflict).
Revisit the bar once zellij-org/zellij#3927 (or its follow-ups) resolves
upstream.

**Adding a theme-following tool later** means picking the narrowest lever it
exposes (env var beats config-path beats nothing) and wiring it the same
way — `zsh/.zshenv` for env-var consumers, deploy-time-symlinked directory
pairs for config-path consumers — rather than inventing a new mechanism.

**Linux stays Mocha-only.** `THEME_MODE` hardcodes `dark` there (no
appearance API targeted), so every mode-selected deploy symlink on Linux
only ever needs the mocha half — deploying an unreachable latte half would
be dead weight. If Linux appearance detection is ever added, every consumer
above already has the light-mode half wired; only the `zsh/.zshenv`
derivation and `linux/deploy.sh`'s symlink set would need to grow.
