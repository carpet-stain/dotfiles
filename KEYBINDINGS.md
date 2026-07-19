# Keybinding chain: Ghostty → Zellij → Neovim

A keystroke passes through up to three layers before it does anything, and each layer can
consume it before the next ever sees it. This is the single reference for who owns what — read
it before adding a new binding anywhere in the chain, so a new conflict doesn't have to be
rediscovered the hard way like the one below was.

## Why this exists

The `support_kitty_keyboard_protocol false` line in `zellij/config.kdl` exists because Neovim
auto-requests the kitty keyboard protocol from any terminal that advertises support (Ghostty
does); with it enabled, Zellij's own `Ctrl`-based mode-switch bindings silently stopped firing
while Neovim was focused — the raw key reached Neovim instead
([zellij-org/zellij#3723](https://github.com/zellij-org/zellij/issues/3723)). It took real
debugging effort to find. This doc exists so the next one doesn't.

## How to read this

Order matters: **Ghostty → Zellij → Neovim**. A key Ghostty handles itself never reaches Zellij.
A key Zellij's own keybind system matches (built-in default, or something in
`zellij/config.kdl`) is consumed there and never reaches the focused pane's program — regardless
of what that program would have done with it. Only an unmatched key passes through raw.

`zellij setup --dump-config` prints Zellij's fully compiled config (built-in defaults + this
repo's overrides merged) — the authoritative source when auditing a new key, not just reading
`config.kdl` in isolation.

## Layer by layer

- **Ghostty** (`ghostty/config`): no custom keybinds. Relies entirely on macOS's own defaults
  (Cmd-C/V/N/Q/K, Cmd +/-/0). `macos-option-as-alt = true` means Option is sent to the terminal
  as a literal Alt/Meta modifier, not macOS's dead-key character composition — everything below
  that says "Alt" depends on this.
- **Zellij** (`zellij/config.kdl`): keeps Zellij's own mode system (`Ctrl p/t/n/o/s/g/q` to enter
  Pane/Tab/Resize/Session/Scroll/Locked mode, `Ctrl q` to quit) as the fallback for everything not
  explicitly listed below, plus its own `shared_except "locked"` defaults — including
  `Alt h/j/k/l` (`MoveFocusOrTab`/`MoveFocus`, not overridden here — see "Design decisions"),
  `Alt f`/`Alt n` (floating-panes/new-pane), `Alt =`/`Alt -` (single-axis resize), `Alt [`/`Alt ]`
  (layout swap). This repo's own `normal`-mode overrides:
  - `Ctrl h/j/k/l` → `vim-zellij-navigator` plugin, `move_focus_or_tab`/`move_focus`: forwards the
    raw keystroke into Neovim (via `smart-splits.nvim`) if it's running in the focused pane,
    otherwise moves Zellij focus directly. Replaces Zellij's own default `Ctrl h` (enter Move
    mode) — `j`/`k`/`l` were unbound in normal mode by default.
  - `Alt ,`/`Alt .` → prefix-less tab switching (`GoToPreviousTab`/`GoToNextTab`).
  - **Resizing a pane**: Zellij's own Resize mode (`Ctrl n` to enter; `h/j/k/l` grow, `H/J/K/L`
    shrink, directionally; `Enter`/`Esc`/`Ctrl n` to exit) or the mode-less `Alt =`/`Alt -`
    shortcut (grows/shrinks the focused pane, non-directional). Deliberately not forwarded to
    Neovim — see "Design decisions".
- **Neovim** (`nvim/lua/config/keymaps.lua` + plugin `keys`/`config` blocks under
  `nvim/lua/plugins/`): LazyVim's own defaults, unmodified except where noted. The only file that
  customizes raw `Ctrl`/`Alt` combos (as opposed to `<leader>`-prefixed ones, which don't reach
  this file from the terminal/multiplexer layers) is `smart-splits.lua`:
  - `Ctrl h/j/k/l` → move cursor between splits (the Neovim-side half of the Zellij forwarding
    above).
  - Resizing an individual Neovim split (as opposed to a Zellij pane) still has LazyVim's own
    defaults: `Ctrl-Up/Down/Left/Right`. Unclaimed anywhere else in the chain, no conflict.
- **zsh** (`zsh/rc.d/keybindings.zsh` + `zsh/rc.d/widgets.zsh`): unclaimed by Zellij or Neovim, so
  an `Alt` binding here reaches the shell's line editor (zle) as-is once the key passes through
  the two layers above. `Alt e` (`^[e`) → builtin `edit-command-line` widget (opens the current
  command buffer in `$EDITOR`, re-executes on save). This depends on Ghostty's
  `macos-option-as-alt` setting from above — without it, `Option+E` is macOS's dead-key
  composition for `é` and never reaches zsh as `Alt+E`.

## Design decisions

### Pane resizing stays on Zellij's own mechanism, not forwarded to Neovim

`smart-splits.nvim` supports an `Alt h/j/k/l` resize keymap, and the same `vim-zellij-navigator`
plugin already forwarding `Ctrl h/j/k/l` for pane movement has a matching `resize` command built
for exactly this pairing. Wiring it up was tried, and found to require _two_ fixes, not one:

1. Zellij's own built-in `Alt h/j/k/l` default (`MoveFocusOrTab`/`MoveFocus`, in
   `shared_except "locked"`) matches before a forwarded-to-Neovim binding would, so `config.kdl`
   would need to override it explicitly (confirmed by testing — Alt+h/j/k/l moved Zellij pane/tab
   focus, not Neovim split size).
2. Once forwarded, `smart-splits.lua`'s `config()` function claiming `Alt h/j/k/l` in Neovim would
   collide with LazyVim's own default `Alt j`/`Alt k` ("move line up/down") in normal mode, since
   the plugin's keymap.set call loads after and wins — silently breaking "move line" in normal
   mode only (insert/visual unaffected, different mode).

Two config changes and a keymap relocation for a feature that's rarely used was more complexity
than it was worth. Decision: **pane resizing uses Zellij's own Resize mode / `Alt =`/`Alt -`
shortcut**, full stop. `smart-splits.lua` only wires `Ctrl h/j/k/l` (movement); `Alt h/j/k/l`
stays exactly as Zellij ships it. This also means LazyVim's own "move line" `Alt j`/`Alt k` never
needed touching — the conflict only existed because of the (reverted) forwarding attempt.

## Adding a new binding

Before binding a new `Ctrl`/`Alt`/`Cmd` combo anywhere in this chain:

1. Check this doc for whether the key is already claimed at an earlier layer.
2. Cross-check `zellij setup --dump-config` — the compiled defaults, not just `config.kdl` — if
   the new binding is inside Zellij or needs to reach through it to Neovim.
3. If it's a Neovim binding, check LazyVim's own defaults
   (`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/keymaps.lua` once installed, or
   [upstream](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua)) for
   an existing claim on the same key in the same mode.
4. Update this doc in the same change.
