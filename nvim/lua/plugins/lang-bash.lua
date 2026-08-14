-- No official LazyVim extra exists for bash/shell/zsh (unlike lang.python,
-- lang.go). Formatting is already a LazyVim default (shfmt); this adds the
-- LSP server and a linter, following LazyVim's standard extension pattern.
-- zsh: LSP only — shellcheck doesn't understand zsh-specific syntax
-- (setopt, glob qualifiers, typeset) and produces constant false positives.
--
-- Prefer a system-installed bash-language-server over Mason's own, same
-- reasoning as mason-tools.lua: not gated on macOS vs. Linux, since a Linux
-- box may already have it on PATH (it's an npm package, and Node itself is
-- payload again per #127/#364's premise reversal — see ADR-0030).
local has_system_bashls = vim.fn.executable("bash-language-server") == 1

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
          -- Keeps the server registered but stops mason-lspconfig's own auto-install,
          -- a path independent of the mason.nvim block below (see mason-tools.lua).
          mason = not has_system_bashls,
          settings = {
            bashIde = {
              -- bashls runs shellcheck across all its filetypes; disabled here so nvim-lint
              -- runs it selectively (sh/bash only — zsh gives constant false positives).
              shellcheckPath = "",
            },
          },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
  -- ensure_installed must name the tool explicitly (AGENTS.md, Structure & conventions).
  -- shellcheck comes from macos/Brewfile instead, shared with lefthook.yml and CI.
  {
    "mason-org/mason.nvim",
    -- mason.nvim's ensure_installed wants Mason's own package name
    -- ("bash-language-server"), not nvim-lspconfig's server name ("bashls").
    opts = { ensure_installed = has_system_bashls and {} or { "bash-language-server" } },
  },
}
