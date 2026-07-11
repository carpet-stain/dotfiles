-- Formatter overrides for filetypes that have no dedicated lang extra (toml,
-- yaml) but still need a formatter wired to the same binaries lefthook.yml/CI
-- use. taplo/yamlfmt are conform.nvim builtins — this just turns them on.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        toml = { "taplo" },
        yaml = { "yamlfmt" },
      },
    },
  },
}
