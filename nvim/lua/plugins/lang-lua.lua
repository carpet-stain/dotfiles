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
          -- selene doesn't search upward for its config, so point it at nvim/selene.toml
          -- explicitly. prepend_args adds to selene's builtin args, doesn't replace them.
          prepend_args = { "--config", vim.fn.stdpath("config") .. "/selene.toml" },
        },
      },
    },
  },
}
