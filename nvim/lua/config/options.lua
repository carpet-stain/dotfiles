-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Zellij answers nvim's native OSC-11 background query itself, with its own
-- (currently Mocha-only) theme color, instead of forwarding it to Ghostty —
-- so native detection reports the wrong background for every pane running
-- inside Zellij (the daily path). Set 'background' explicitly from
-- THEME_MODE instead: this has a real script id, so nvim's own OSC-11
-- autocmd (runtime/lua/vim/_core/defaults.lua) disables itself at VimEnter
-- rather than fighting our value. THEME_MODE not landing until #441; absent
-- treated as dark.
vim.o.background = vim.env.THEME_MODE == "light" and "light" or "dark"
