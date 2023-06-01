-- What is the name of the directory containing this file?
vim.api.nvim_command("let s:portable=expand('<sfile>:p:h')")

-- Add the directory to 'runtimepath'
vim.api.nvim_command("let &runtimepath=printf('%s,%s/lua', s:portable, s:portable)")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
