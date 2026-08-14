-- Show gitignored and dotfiles in the explorer by default — LazyVim's own
-- defaults hide both, but this repo routinely has gitignored/dotfiles
-- (.envrc.local, ssh/config.local, .zshenv, .gitignore) that need editing
-- directly.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_gitignored = false,
          hide_dotfiles = false,
        },
        -- OS-level watcher, not nvim autocmds, so the tree picks up changes made
        -- outside this instance (git, a terminal, an agent) without a manual refresh.
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true,
        },
      },
    },
  },
}
