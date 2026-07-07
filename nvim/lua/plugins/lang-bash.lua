-- No official LazyVim extra exists for bash/shell/zsh (unlike lang.python,
-- lang.go). Formatting is already a LazyVim default (shfmt); this adds the
-- LSP server and a linter, following LazyVim's standard extension pattern.
-- zsh: LSP only — shellcheck doesn't understand zsh-specific syntax
-- (setopt, glob qualifiers, typeset) and produces constant false positives.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
      },
    },
  },
  -- nvim-lspconfig's `servers` table is supposed to auto-install LSP servers
  -- via Mason too, but that path is unreliably slow/async in practice (and
  -- standalone linter CLIs like shellcheck don't go through it at all) — so
  -- list both explicitly here for a deterministic `deploy.zsh` bootstrap.
  {
    "mason-org/mason.nvim",
    -- mason.nvim's ensure_installed wants Mason's own package name
    -- ("bash-language-server"), not nvim-lspconfig's server name ("bashls").
    opts = { ensure_installed = { "bash-language-server", "shellcheck" } },
  },
}
