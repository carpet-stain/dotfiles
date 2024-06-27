--stylua: ignore start
_G.Config = {}

-- Initialization ===========================================================

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = { "git", "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd("packadd mini.nvim | helptags ALL")
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps'
require("mini.deps").setup({ path = { package = path_package } })

-- Define helpers
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
local load = function(spec, opts)
  return function()
    opts = opts or {}
    local slash = string.find(spec, "/[^/]*$") or 0
    local name = opts.init or string.sub(spec, slash + 1)
    if slash ~= 0 then
      add(vim.tbl_deep_extend("force", { source = spec }, opts.add or {}))
    end
    require(name)
    if opts.setup then require(name).setup(opts.setup) end
  end
end

-- Settings and mappings ====================================================
now(load("settings"))
now(load("mappings"))
now(load("autocmds"))
now(load("usercmds"))

-- Colorscheme ==============================================================
add("catppuccin/nvim")
now(function() vim.cmd("colorscheme catppuccin-mocha") end)

-- Mini.nvim ================================================================
add({ name = "mini.nvim", depends = { "nvim-tree/nvim-web-devicons" } })

now(load("plugins.mini.basics"))
now(load("plugins.mini.sessions"))
now(load("plugins.mini.starter"))

later(load("plugins.mini.notify"))
later(load("plugins.mini.statusline"))
later(load("mini.tabline", { setup = {} }))

later(load("mini.align",      { setup = {} }))
later(load("mini.animate",    { setup = {} }))
later(load("mini.bracketed",  { setup = {} }))
later(load("mini.bufremove",  { setup = {} }))
later(load("mini.colors",     { setup = {} }))
later(load("mini.comment",    { setup = {} }))
later(load("mini.cursorword", { setup = {} }))
later(load("mini.extra",      { setup = {} }))
later(load("mini.jump",       { setup = {} }))
later(load("mini.move",       { setup = {} }))
later(load("mini.operators",  { setup = {} }))
later(load("mini.pairs",      { setup = {} }))
later(load("mini.splitjoin",  { setup = {} }))
later(load("mini.surround",   { setup = {} }))
later(load("mini.trailspace", { setup = {} }))
later(load("mini.visits",     { setup = {} }))

later(load("plugins.mini.ai"))
later(load("plugins.mini.clue"))
later(load("plugins.mini.diff"))
later(load("plugins.mini.files"))
later(load("plugins.mini.git"))
later(load("plugins.mini.hipatterns"))
later(load("plugins.mini.indentscope"))
later(load("plugins.mini.jump2d"))
later(load("plugins.mini.misc"))
later(load("plugins.mini.pick"))
later(load("plugins.mini.map"))
later(load("plugins.mini.completion"))

-- Other plugins ============================================================

later(load("stevearc/conform.nvim",              { init = "plugins.conform" }))
later(load("mfussenegger/nvim-lint",             { init = "plugins.nvim-lint"}))
later(load("MeanderingProgrammer/markdown.nvim", { init = "plugins.render-markdown"}))

later(load("nvim-treesitter/nvim-treesitter", {
  init = "plugins.treesitter",
  add = { hooks = { post_checkout = function() vim.cmd("TSUpdate") end} },
}))

later(load("nvim-treesitter/nvim-treesitter-context", {
  init = "treesitter-context",
  setup = {},
}))

later(load("neovim/nvim-lspconfig", {
  init = "plugins.lspconfig",
  add = {
    depends = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "folke/lazydev.nvim"
    },
  },
}))

--stylua: ignore end
-- vim: ts=2 sts=2 sw=2 et
