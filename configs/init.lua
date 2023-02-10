require('impatient')

-- autocmds
local autocmd = vim.api.nvim_create_autocmd

-- dont list quickfix buffers
autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- Set default 'runtimepath' without ~/.vim folders
-- let &runtimepath=printf('%s/vimfiles,%s,%s/vimfiles/after', $VIM, $VIMRUNTIME, $VIM)
-- What is the name of the directory containing this file?
-- let s:portable=expand('<sfile>:p:h')
-- Add the directory to 'runtimepath'
-- let &runtimepath=printf('%s,%s,%s/after', s:portable, &runtimepath, s:portable)
-- let &packpath=&runtimepath

-- Use sensible XDG paths
-- set directory=$XDG_CACHE_HOME/nvim/swap//
-- set undodir=$XDG_CACHE_HOME/nvim/undo//
-- set backupdir=$XDG_CACHE_HOME/nvim/backup//

-- Enable backups and undo

vim.bo.swapfile = true
vim.o.undofile = true

vim.o.shiftround = true -- round indent to multiple shiftwidth
vim.o.showmatch = true --show matching brackets when text indicator is over them
vim.o.ignorecase = true -- ignore case when searching
vim.o.smartcase = true -- when searching try to be smart about cases
vim.wo.wrap = false -- don't wrap lines
vim.o.lazyredraw = true -- helps dealing with flickering
vim.o.clipboard = 'unnamed,unnamedplus' -- merge clipboard with x11 and mac
vim.opt.listchars = {
  tab = '>-',
  trail = '·',
  extends = '▶',
  precedes = '◀',
}
vim.opt.list = true
vim.wo.number = true -- show line numbers ...
vim.wo.relativenumber = true -- and use relative style numbers
vim.wo.cursorline = true -- highlight line with cursor
vim.o.shortmess = vim.o.shortmess .. "c" -- Shut off completion messages
-- set whichwrap+=<,>,h,l,[,] -- autowrap to next line for cursor movements
vim.o.splitbelow = true -- when splitting windows put new ones below ...
vim.o.splitright  = true -- ...and to the right
vim.o.path = vim.o.path .. '**' -- search subfolders recursively
vim.opt.fillchars = { 
  diff = ' ',
} -- set <space> as fill character for diffs on string removal (default is <minus> char)
vim.o.updatetime = 100 -- controls how often should focus events and how often should it write to swap

-- command line completion
vim.o.wildmode = 'longest:full,full'

-- -- Scrolling
vim.o.scrolloff = 8 --start scrolling when we're 8 lines away from margins
vim.o.sidescrolloff = 8 --start sidescrolling 8 chars away from margins

-- -- Tabs, make them 4 spaces by default
vim.bo.expandtab = true
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.shiftwidth = 4

vim.o.rtp = vim.o.rtp .. '${HOMEBREW_REPOSITORY}/opt/fzf'

-- Lualine
require('lualine').setup {
  options = {
    theme = 'solarized_dark'
  }
}
-- -- Colorscheme
vim.o.termguicolors = true
vim.cmd [[colorscheme flattened_dark]]

-- -- Comment
require('Comment').setup()

-- nvim-tree
require("nvim-tree").setup({
  filters = {
    dotfiles = false,
    exclude = { vim.fn.stdpath "config" .. "/lua/custom" },
  },
  disable_netrw = true,
  hijack_netrw = true,
  open_on_setup = false,
  ignore_ft_on_setup = { "alpha" },
  hijack_cursor = true,
  hijack_unnamed_buffer_when_opening = false,
  update_cwd = true,
  update_focused_file = {
    enable = true,
    update_cwd = false,
  },
  view = {
    adaptive_size = true,
    side = "left",
    width = 25,
    hide_root_folder = true,
  },
  git = {
    enable = false,
    ignore = true,
  },
  filesystem_watchers = {
    enable = true,
  },
  actions = {
    open_file = {
      resize_window = true,
    },
  },
  renderer = {
    highlight_git = false,
    highlight_opened_files = "none",

    indent_markers = {
      enable = false,
    },

    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = false,
      },
    },
  },
})

-- indent-blankline
require("indent_blankline").setup()

-- gitsigns
require('gitsigns').setup()

-- mason
require("mason").setup{
  PATH = "skip",
  ui = {
    keymaps = {
      toggle_server_expand = "<CR>",
      install_server = "i",
      update_server = "u",
      check_server_version = "c",
      update_all_servers = "U",
      check_outdated_servers = "C",
      uninstall_server = "X",
      cancel_installation = "<C-c>",
    },
  },
  max_concurrent_installers = 10,
}

-- lspconfig
require'lspconfig'.sumneko_lua.setup {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}

-- nvim-cmp
local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    -- { name = 'vsnip' }, -- For vsnip users.
    { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
  capabilities = capabilities
}

-- treesitter
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "bash", "dockerfile", "json", "java", "lua", "make", "python", "regex", "rego", "toml", "typescript", "vim", "yaml"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

-- -- fzf
require('fzf-lua').setup{}
-- nvim-web-devicons
require'nvim-web-devicons'.setup{}

-- let g:fzf_action = {
--     \ 'ctrl-e': 'tab split',
--     \ 'ctrl-x': 'split',
--     \ 'ctrl-v': 'vsplit' }

-- let g:fzf_colors = {
--     \ 'fg':      ['fg', 'Normal'],
--     \ 'bg':      ['bg', 'Normal'],
--     \ 'hl':      ['fg', 'Comment'],
--     \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
--     \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
--     \ 'hl+':     ['fg', 'Statement'],
--     \ 'info':    ['fg', 'PreProc'],
--     \ 'border':  ['fg', 'Ignore'],
--     \ 'prompt':  ['fg', 'Conditional'],
--     \ 'pointer': ['fg', 'Exception'],
--     \ 'marker':  ['fg', 'Keyword'],
--     \ 'spinner': ['fg', 'Label'],
--     \ 'header':  ['fg', 'Comment'] }

-- let g:fzf_history_dir = '~/.local/share/fzf-history'

-- let g:fzf_files_options = '--preview="head -'.&lines.' {}"'

-- let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

-- -- GitGutter
-- -- disable standard git gutter mappings
-- let g:gitgutter_map_keys=0

-- -- show preview popup for hunks
-- let g:gitgutter_preview_win_floating=1

-- -- Key Mappings
-- -- map spacebar as leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
vim.keymap.set("n", "<leader>vv", ":NvimTreeToggle<CR>", { silent = true })
-- Move selected lines in visual mode up or down, awesome!
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})



-- -- if suggestions windows present, then <Enter> accepts selection
-- -- else use delimitMateCR mapping
-- inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : '<Plug>delimitMateCR'

-- let g:tmux_navigator_no_mappings = 1
-- let g:tmux_navigator_save_on_switch = 1

-- -- use alt+arrows to switch between splits and tmux panes
-- nnoremap <silent> <M-Left> :TmuxNavigateLeft<CR>
-- nnoremap <silent> <M-Down> :TmuxNavigateDown<CR>
-- nnoremap <silent> <M-Up> :TmuxNavigateUp<CR>
-- nnoremap <silent> <M-Right> :TmuxNavigateRight<CR>

-- -- crtl+left/right to switch buffers in normal mode
-- nmap <C-Left> <Plug>AirlineSelectPrevTab
-- nmap <C-Right> <Plug>AirlineSelectNextTab

-- -- visual shifting (does not exit visual mode)
-- vnoremap < <gv
-- vnoremap > >gv

-- -- visual paste without yanking
-- vnoremap p "_c<C-r><C-o>+<Esc>

-- -- accept commands with accidential shift key pressed
-- command! -bang -nargs=* -complete=file E e<bang> <args>
-- command! -bang -nargs=* -complete=file W w<bang> <args>
-- command! -bang -nargs=* -complete=file Wq wq<bang> <args>
-- command! -bang -nargs=* -complete=file WQ wq<bang> <args>
-- command! -bang Wa wa<bang>
-- command! -bang WA wa<bang>
-- command! -bang Q q<bang>
-- command! -bang QA qa<bang>
-- command! -bang Qa qa<bang>

-- -- allow the . to execute once for each line of a visual selection
-- vnoremap . :normal .<CR>

-- -- I fat finger this too often. Command history window, you won't be missed
-- -- Ctrl+f in command line in case you really need it
-- nnoremap q: :q

-- -- allow saving of files as sudo when I forgot to start vim using sudo
-- cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

-- -- Markdown
-- let g:vim_markdown_folding_disabled=1
-- let g:vim_markdown_no_default_key_mappings=1
-- let g:vim_markdown_toc_autofit=1
-- let g:vim_markdown_conceal=0
-- let g:vim_markdown_conceal_code_blocks=0
-- let g:vim_markdown_fenced_languages=['bash=sh', 'ini=dosini', 'viml=vim']

-- -- Test
-- let g:test#strategy='vimterminal'

-- -- Treesitter
-- lua << EOF
-- require'nvim-treesitter.configs'.setup {
--   -- A list of parser names, or "all"
--   ensure_installed = { "bash", "dockerfile", "json", "java", "lua", "make", "python", "regex", "rego", "toml", "typescript", "vim", "yaml-- },

--   -- Install parsers synchronously (only applied to `ensure_installed`)
--   sync_install = false,

--   highlight = {
--     -- `false` will disable the whole extension
--     enable = true,

--     -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
--     -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
--     -- Using this option may slow down your editor, and you may see some duplicate highlights.
--     -- Instead of true it can also be a list of languages
--     additional_vim_regex_highlighting = false,
--   },
-- }
-- EOF

-- -- UndoTree
-- let g:undotree_WindowLayout=4
-- let g:undotree_ShortIndicators=1

-- -- WhichKey
local wk = require("which-key")
wk.register({
    e = { ":Fern . -drawer -reveal=%<CR>", "File drawer"},
    f = {
      name = "Fuzzy Search", -- optional group name
      f = { ":FzfLua files<CR>", "Find File" }, -- create a binding with label
      b = { ":Buffers<CR>", "Open buffers" },
      l = { ":Lines<CR>", "Lines in loaded buffers" },
      c = { ":Commands<CR>", "Commands"},
      m = { ":Maps<CR>", "Normal mode mappings"},
    },
    h = {
        name = "Hunks",
        p = { "<Plug>(GitGutterPreviewHunk)", "Preview" },
        u = { "<Plug>(GitGutterUndoHunk)", "Undo" },
        s = { "<Plug>(GitGutterStageHunk)", "Stage" }
    },
    a = { ":Ag<CR>", "Ag Search" },
    q = { ":QToggle<CR>", "Quickfix window" },
    u = { ":UndotreeToggle<CR>", "Undotree" }
}, { prefix = "<leader>" })

-- -- Wilder
-- call wilder#setup({'modes': [':', '/', '?']})

-- call wilder#set_option('renderer', wilder#wildmenu_renderer(
--   \ wilder#wildmenu_airline_theme({
--   \   'highlighter': wilder#basic_highlighter(),
--   \ })))
