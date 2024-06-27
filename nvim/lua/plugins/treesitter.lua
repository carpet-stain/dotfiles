require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "go",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
  },
  auto_install = true,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
    disable = { "markdown" },
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
})
