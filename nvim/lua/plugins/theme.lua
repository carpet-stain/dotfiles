return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- colorschemes must load before all other startup plugins
    opts = {
      flavour = "auto", -- follows 'background', set from THEME_MODE in config/options.lua
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
