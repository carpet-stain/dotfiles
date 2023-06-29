return {
  "folke/twilight.nvim",
  "jose-elias-alvarez/typescript.nvim",

  {
    "echasnovski/mini.splitjoin",
    opts = { mappings = { toggle = "J" } },
    keys = {
      { "J", desc = "Split/Join" },
    },
  },
  {
    "Wansmer/treesj",
    enabled = false,
    keys = {
      { "J", "<cmd>TSJToggle<cr>" },
    },
    opts = { use_default_keymaps = false, max_join_length = 300 },
    -- dev = true,
  },

  {
    "cshuaimin/ssr.nvim",
    keys = {
      {
        "<leader>sR",
        function()
          require("ssr").open()
        end,
        mode = { "n", "x" },
        desc = "Structural Replace",
      },
    },
  },

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      plugins = {
        tmux = true,
        alacritty = { enabled = false, font = "+2" },
      },
    },
    keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  },

  {
    "andymass/vim-matchup",
    event = "BufReadPost",
    init = function()
      vim.o.matchpairs = "(:),{:},[:],<:>"
    end,
    config = function()
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
    end,
  },

  -- { "simnalamburt/vim-mundo", event = "BufReadPre", cmd = "MundoToggle" },

  "melvio/medical-spell-files",
}
