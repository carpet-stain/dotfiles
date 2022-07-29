" Set default 'runtimepath' without ~/.vim folders
let &runtimepath=printf('%s/vimfiles,%s,%s/vimfiles/after', $VIM, $VIMRUNTIME, $VIM)
" What is the name of the directory containing this file?
let s:portable=expand('<sfile>:p:h')
" Add the directory to 'runtimepath'
let &runtimepath=printf('%s,%s,%s/after', s:portable, &runtimepath, s:portable)
let &packpath=&runtimepath

" Use sensible XDG paths
set directory=$XDG_CACHE_HOME/nvim/swap//
set undodir=$XDG_CACHE_HOME/nvim/undo//
set backupdir=$XDG_CACHE_HOME/nvim/backup//

" Enable backups and undo
set backup
set undofile

set shiftround " round indent to multiple shiftwidth
set showmatch " show matching brackets when text indicator is over them
set hlsearch " highlight search results
set ignorecase " ignore case when searching
set smartcase " when searching try to be smart about cases
set nowrap " don't wrap lines
set ttyfast " indicate fast tty connetion
set lazyredraw " helps dealing with flickering
set clipboard=unnamed,unnamedplus " merge clipboard with x11 and mac
set list listchars=tab:>-,trail:·,extends:►,precedes:◄ " indicate various special chars
set number " show line numbers ...
set relativenumber " and use relative style numbers
set cursorline " highlight line with cursor
set showcmd " show partial commands in bottom left corner
set shortmess+=c "Shut off completion messages
set whichwrap+=<,>,h,l,[,] " autowrap to next line for cursor movements
set splitbelow " when splitting windows put new ones below ...
set splitright " ...and to the right
set path+=** " search subfolders recursively
set fillchars=diff:\ , " set <space> as fill character for diffs on string removal (default is <minus> char)
set updatetime=100 "controls how often should focus events and how often should it write to swap

" command line completion
set wildmode=longest:full,full

" Scrolling
set scrolloff=8 " start scrolling when we're 8 lines away from margins
set sidescroll=1 " enable sidescrolling too
set sidescrolloff=8 " start sidescrolling 8 chars away from margins

" Tabs, make them 4 spaces by default
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

set rtp+=/usr/local/opt/fzf

" Airline
" force solarized theme
let g:airline_theme='solarized'
" don't show expected encoding
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
" remove separator symbols
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_left_alt_sep=''
let g:airline_right_alt_sep=''
" use plain ascii symbols, unicode symbols don't look nice with every font
let g:airline_symbols_ascii=1
" Automatically displays all buffers when there's only one tab open.
let g:airline#extensions#tabline#enabled = 1

" Colorscheme
set termguicolors
set background=dark
colorscheme solarized8_flat

" Comment
lua << EOF
require('Comment').setup()
EOF

" Committia
let g:committia_hooks = {}
function! g:committia_hooks.edit_open(info)
  " Additional settings
  setlocal spell

  " Disable side scrolling for commit message
  setlocal sidescroll=0 sidescrolloff=0

  " If no commit message, start with insert mode
  if a:info.vcs ==# 'git' && getline(1) ==# ''
    startinsert
  end

  " Scroll the diff window from insert mode
  " Map <C-n> and <C-p>
  imap <buffer><C-n> <Plug>(committia-scroll-diff-down-half)
  imap <buffer><C-p> <Plug>(committia-scroll-diff-up-half)
endfunction

" EasyMotion
" disable default easymotion mappings
" enable them later in which-key config
let g:EasyMotion_do_mapping=0

" Disable netrw.
let g:loaded_netrw  = 1
let g:loaded_netrwPlugin = 1
let g:loaded_netrwSettings = 1
let g:loaded_netrwFileHandlers = 1

" Fern
let g:fern#default_hidden = 1
augroup my-fern-hijack
  autocmd!
  autocmd BufEnter * ++nested call s:hijack_directory()
augroup END

function! s:hijack_directory() abort
  let path = expand('%:p')
  if !isdirectory(path)
    return
  endif
  bwipeout %
  execute printf('Fern %s', fnameescape(path))
endfunction

" You need this otherwise you cannot switch modified buffer
set hidden

" fzf
let g:fzf_action = {
    \ 'ctrl-e': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

let g:fzf_colors = {
    \ 'fg':      ['fg', 'Normal'],
    \ 'bg':      ['bg', 'Normal'],
    \ 'hl':      ['fg', 'Comment'],
    \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
    \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
    \ 'hl+':     ['fg', 'Statement'],
    \ 'info':    ['fg', 'PreProc'],
    \ 'border':  ['fg', 'Ignore'],
    \ 'prompt':  ['fg', 'Conditional'],
    \ 'pointer': ['fg', 'Exception'],
    \ 'marker':  ['fg', 'Keyword'],
    \ 'spinner': ['fg', 'Label'],
    \ 'header':  ['fg', 'Comment'] }

let g:fzf_history_dir = '~/.local/share/fzf-history'

let g:fzf_files_options = '--preview="head -'.&lines.' {}"'

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

" GitGutter
" disable standard git gutter mappings
let g:gitgutter_map_keys=0

" show preview popup for hunks
let g:gitgutter_preview_win_floating=1

" Key Mappings
" map spacebar as leader key
map <Space> <leader>

" if suggestions windows present, then <Enter> accepts selection
" else use delimitMateCR mapping
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : '<Plug>delimitMateCR'

let g:tmux_navigator_no_mappings = 1
let g:tmux_navigator_save_on_switch = 1

" use alt+arrows to switch between splits and tmux panes
nnoremap <silent> <M-Left> :TmuxNavigateLeft<CR>
nnoremap <silent> <M-Down> :TmuxNavigateDown<CR>
nnoremap <silent> <M-Up> :TmuxNavigateUp<CR>
nnoremap <silent> <M-Right> :TmuxNavigateRight<CR>

" crtl+left/right to switch buffers in normal mode
nmap <C-Left> <Plug>AirlineSelectPrevTab
nmap <C-Right> <Plug>AirlineSelectNextTab

" visual shifting (does not exit visual mode)
vnoremap < <gv
vnoremap > >gv

" visual paste without yanking
vnoremap p "_c<C-r><C-o>+<Esc>

" accept commands with accidential shift key pressed
command! -bang -nargs=* -complete=file E e<bang> <args>
command! -bang -nargs=* -complete=file W w<bang> <args>
command! -bang -nargs=* -complete=file Wq wq<bang> <args>
command! -bang -nargs=* -complete=file WQ wq<bang> <args>
command! -bang Wa wa<bang>
command! -bang WA wa<bang>
command! -bang Q q<bang>
command! -bang QA qa<bang>
command! -bang Qa qa<bang>

" allow the . to execute once for each line of a visual selection
vnoremap . :normal .<CR>

" I fat finger this too often. Command history window, you won't be missed
" Ctrl+f in command line in case you really need it
nnoremap q: :q

" allow saving of files as sudo when I forgot to start vim using sudo
cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" Markdown
let g:vim_markdown_folding_disabled=1
let g:vim_markdown_no_default_key_mappings=1
let g:vim_markdown_toc_autofit=1
let g:vim_markdown_conceal=0
let g:vim_markdown_conceal_code_blocks=0
let g:vim_markdown_fenced_languages=['bash=sh', 'ini=dosini', 'viml=vim']

" Test
let g:test#strategy='vimterminal'

" Treesitter
lua << EOF
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "bash", "dockerfile", "json", "java", "lua", "make", "python", "regex", "rego", "toml", "typescript", "vim", "yaml" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

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
EOF

" UndoTree
let g:undotree_WindowLayout=4
let g:undotree_ShortIndicators=1

" WhichKey
lua << EOF
local wk = require("which-key")
wk.register({
    e = { ":Fern . -drawer -reveal=%<CR>", "File drawer"},
    f = {
      name = "Fuzzy Search", -- optional group name
      f = { ":Files<CR>", "Find File" }, -- create a binding with label
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

    ["<Space>" ] = {
        name = "Easymotion",
        f = { "<Plug>(easymotion-f)", "Find char to the right" },
        F = { "<Plug>(easymotion-F)", "Find char to the left" },
        t = { "<Plug>(easymotion-t)", "Till before the char to the right" },
        T = { "<Plug>(easymotion-T)", "Till after the char to the left" },
        w = { "<Plug>(easymotion-w)", "Beginning of word forward" },
        W = { "<Plug>(easymotion-W)", "Beginning of WORD forward" },
        b = { "<Plug>(easymotion-b)", "Beginning of word backward" },
        B = { "<Plug>(easymotion-B)", "Beginning of WORD backward" },
        e = { "<Plug>(easymotion-e)", "End of word forward" },
        E = { "<Plug>(easymotion-E)", "End of WORD forward" },
        g = {
            name = "End of word/WORD backward",
            e = { "<Plug>(easymotion-ge)", "End of word backward" },
            E = { "<Plug>(easymotion-gE)", "End of WORD backward" }
        },
        j  = { "<Plug>(easymotion-j)", "Line downward" },
        k  = { "<Plug>(easymotion-k)", "Line upward" },
        n  = { "<Plug>(easymotion-n)", "Jump to latest  or forward" },
        N  = { "<Plug>(easymotion-N)", "Jump to latest  or backward" },
        s  = { "<Plug>(easymotion-s)", "Find char forward and backward" }
    },
    a = { ":Ag<CR>", "Ag Search" },
    q = { ":QToggle<CR>", "Quickfix window" },
    u = { ":UndotreeToggle<CR>", "Undotree" }
}, { prefix = "<leader>" })
EOF

" Wilder
call wilder#setup({'modes': [':', '/', '?']})

call wilder#set_option('renderer', wilder#wildmenu_renderer(
  \ wilder#wildmenu_airline_theme({
  \   'highlighter': wilder#basic_highlighter(),
  \ })))
