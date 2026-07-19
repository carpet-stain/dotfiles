-- Lua isn't a LazyVim lang extra (lazy.nvim itself is Lua, so formatting —
-- stylua — is already a core conform default). This adds the missing half:
-- a linter, via the same selene binary and config lefthook.yml/CI use when
-- one's already on PATH (e.g. via macos/Brewfile) — mason-tools.lua's
-- `dev_tools` table Mason-installs a fallback copy of selene/stylua when
-- neither is, same treatment as lua_ls/gopls/pyright.
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        lua = { "selene" },
      },
      linters = {
        selene = {
          -- selene doesn't search upward for its config the way stylua does,
          -- so point it at nvim/selene.toml explicitly regardless of cwd.
          -- prepend_args (a LazyVim nvim-lint extension) adds this ahead of
          -- selene's builtin `--display-style json -`, rather than replacing it.
          prepend_args = { "--config", vim.fn.stdpath("config") .. "/selene.toml" },
        },
      },
    },
  },
}
