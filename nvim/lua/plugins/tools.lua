return {

  -- {
  -- 	"nvim-orgmode/orgmode",
  -- 	dependencies = "nvim-treesitter/nvim-treesitter",
  -- 	event = "VeryLazy",
  -- 	opts = {},
  -- 	config = function()
  -- 		require("orgmode").setup_ts_grammar()
  -- 	end,
  -- },

  -- neorg
  {
    "nvim-neorg/neorg",
    enabled = false,
    ft = "norg",
    opts = {
      load = {
        ["core.defaults"] = {},
        ["core.norg.concealer"] = {},
        ["core.norg.completion"] = {
          config = { engine = "nvim-cmp" },
        },
        ["core.integrations.nvim-cmp"] = {},
      },
    },
  },

  -- markdown preview
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    keys = {
      {
        "<leader>op",
        function()
          local peek = require("peek")
          if peek.is_open() then
            peek.close()
          else
            peek.open()
          end
        end,
        desc = "Peek (Markdown Preview)",
      },
    },
    opts = { theme = "dark" }, -- 'dark' or 'light'
    init = function()
      require("which-key").register({
        ["<leader>o"] = { name = "+open" },
      })
    end,
  },

  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function()
      require("numb").setup()
    end,
  },

  "wellle/targets.vim",

  {
    "bennypowers/nvim-regexplainer",
    event = "BufRead",
    dependencies = { "nvim-treesitter/nvim-treesitter", "MunifTanjim/nui.nvim" },
    config = true,
  },
}
