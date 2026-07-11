-- LazyVim's official lang extras (python, go) declare their LSP servers via
-- nvim-lspconfig's `servers` table, which is supposed to auto-install them
-- through Mason too — but that path didn't fire at all during a headless
-- `deploy.zsh` bootstrap (confirmed via ~/.local/state/nvim/mason.log: no
-- install was even attempted). Listing them explicitly here, on top of the
-- extras, makes a fresh machine's install deterministic.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
        "gopls",
        "json-lsp",
        "yaml-language-server",
        "marksman",
        "markdown-toc",
      },
    },
  },
}
