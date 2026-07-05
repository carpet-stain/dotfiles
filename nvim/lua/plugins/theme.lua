return {
  -- 1. Install the theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Make sure this loads first
  },

  -- 2. Configure LazyVim to use Catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}