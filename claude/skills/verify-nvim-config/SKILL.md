---
name: verify-nvim-config
description: >-
  Confirms a Neovim plugin-config change took effect at runtime by launching the deployed
  config headless and reading back the plugin's own merged module state — proving the option
  applied, not just that the Lua file parses. Use after changing or reviewing a plugin's
  options in nvim/lua/plugins/*.lua (a colorscheme, a formatter, a filter, a keymap) and you
  need to verify the merged runtime value, not lint or parse it.
allowed-tools: Read, Glob, Grep, Bash
---

# Verify Nvim Config

Proves an nvim plugin option took effect at **runtime**, not that its file parses. LazyVim
merges your `nvim/lua/plugins/*.lua` opts with the plugin's and LazyVim's own defaults; a file
that parses cleanly can still merge to the wrong value (wrong key, wrong nesting, overridden by
an extra). The only proof is launching the config and reading the plugin's merged state back.

Targeted introspection — "did this one option apply" — not a general nvim test suite.

## Technique — headless introspection

Launch the **deployed** config (`~/.config/nvim`, whatever repo it's symlinked from — never
hardcode a checkout path) headless and print the plugin's merged runtime value:

```sh
nvim --headless -c 'lua io.write(vim.inspect(require("<module>").<field>) .. "\n")' -c 'qa'
```

`require("<module>")` forces lazy.nvim to load that plugin through its normal loader, so what
prints is the fully merged config, not the file's literal opts. Compare the printed value
against what the plugin file sets. Match = the option applied.

If `~/.config/nvim` isn't deployed, fall back to this repo's tree —
`NVIM_APPNAME=... nvim ...` or `nvim -u nvim/init.lua` — and say so; it proves the source, not
the deployed symlink.

## Pick the query for this plugin

Different plugins expose merged config differently — this judgment is why it's a skill, not a
fixed script. Read the changed file, then choose:

- **Module field** — `require("conform").formatters_by_ft.toml` → `{ "taplo" }`. Works when
  the plugin stores merged opts on its module (conform, and most `opts`-based plugins).
- **Vim global / option** — `vim.g.colors_name`, `vim.o.<opt>`. For settings a plugin applies
  to editor state (LazyVim's `colorscheme` opt ends up in `vim.g.colors_name`).
- **Plugin command / API** — `:ConformInfo`, a source's `get_state()`, `vim.api.nvim_get_keymap`
  / `nvim_get_autocmds`. For config not surfaced as a plain module field. Neo-tree, for one,
  leaves `require("neo-tree").config` nil until its setup runs — query its state or a
  `:NeoTree*` command instead of a module field.

When a module field returns nil, that's a "wrong query," not a failed option — switch strategy,
don't conclude the change didn't apply.

## Report

State the exact command, its output, the plugin option checked, and whether the merged value
matches the file. Note any fallback (repo tree instead of deployed `~/.config/nvim`).
