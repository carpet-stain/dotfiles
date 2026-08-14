-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- OSC-11 detection is wrong inside Zellij, so derive from THEME_MODE (ADR-0034, #440).
-- Setting it here also makes nvim's own OSC-11 autocmd stand down at VimEnter.
vim.o.background = vim.env.THEME_MODE == "light" and "light" or "dark"
