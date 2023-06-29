--  ╭─────────────────────────────────────────────────────────────────────────────╮
--  │            Keymaps are automatically loaded on the VeryLazy event           │
--  │                     Default keymaps that are always set:                    │
--  │ https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua │
--  ╰─────────────────────────────────────────────────────────────────────────────╯

local util = require("util")

-- util.cowboy()

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- Move to window using the movement keys
vim.keymap.set("n", "<left>", "<C-w>h")
vim.keymap.set("n", "<down>", "<C-w>j")
vim.keymap.set("n", "<up>", "<C-w>k")
vim.keymap.set("n", "<right>", "<C-w>l")

-- change word with <c-c>
vim.keymap.set("n", "<C-c>", "<cmd>normal! ciw<cr>a")

-- plenary testing
vim.keymap.set("n", "<leader>tt", function()
  util.test(true)
end, { desc = "Test File" })
vim.keymap.set("n", "<leader>tT", function()
  util.test()
end, { desc = "Test All Files" })
require("which-key").register({
  ["<leader>t"] = { name = "+test" },
})

-- run lua
vim.keymap.set("n", "<leader>cR", util.runlua, { desc = "Run Lua" })

--  ╭──────────╮
--  │ Commands │
--  ╰──────────╯
util.command("ToggleBackground", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end)
