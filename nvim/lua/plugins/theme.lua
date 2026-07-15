return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- colorschemes must load before all other startup plugins
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
