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
          -- Keep the server registered (it still attaches if the binary
          -- happens to be on PATH) but stop mason-lspconfig's own
          -- auto-install when a system copy is already present — a path
          -- independent of this file's mason.nvim block below (see
          -- mason-tools.lua's comment for why).
          mason = not has_system_bashls,
          settings = {
            bashIde = {
              -- bash-language-server runs shellcheck internally across all its
              -- filetypes; disabling it here so nvim-lint can run shellcheck
              -- selectively (sh/bash only — zsh produces constant false positives).
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
  -- nvim-lspconfig's `servers` table is supposed to auto-install LSP servers
  -- via Mason too, but that path is unreliably slow/async in practice — so
  -- list it explicitly here for a deterministic `deploy.zsh` bootstrap.
  -- shellcheck itself comes from macos/Brewfile now (shared with lefthook.yml
  -- and CI), not Mason — one copy on PATH instead of two.
  {
    "mason-org/mason.nvim",
    -- mason.nvim's ensure_installed wants Mason's own package name
    -- ("bash-language-server"), not nvim-lspconfig's server name ("bashls").
    opts = { ensure_installed = has_system_bashls and {} or { "bash-language-server" } },
  },
}
