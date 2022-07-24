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

"set rtp+=/usr/local/opt/fzf
set rtp+=/usr/bin/fzf

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
" enable support of more colors
if has('termguicolors')
    set termguicolors
    let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
endif

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
let g:fern#default_hidden=1
function! s:init_fern() abort
    if !exists("b:fern_is_preview")
    let b:fern_is_preview = 0
    endif
    function! FernPreviewToggle()
    if b:fern_is_preview
        :execute "normal \<Plug>(fern-action-preview:close)"
        :execute "normal \<Plug>(fern-action-preview:auto:disable)"
        nunmap <buffer> <C-d>
        nunmap <buffer> <C-u>
        let b:fern_is_preview = 0
    else
        :execute "normal \<Plug>(fern-action-preview:open)"
        :execute "normal \<Plug>(fern-action-preview:auto:enable)<Plug>(fern-action-preview:open)"
        nmap <silent> <buffer> <C-d> <Plug>(fern-action-preview:scroll:down:half)
        nmap <silent> <buffer> <C-u> <Plug>(fern-action-preview:scroll:up:half)
        let b:fern_is_preview = 1
    endif
    endfunction

nmap <silent> <buffer> p :call FernPreviewToggle()<CR>
endfunction

function! s:fern_settings() abort
    nmap <silent> <buffer> <expr> <Plug>(fern-quit-or-close-preview) fern_preview#smart_preview("\<Plug>(fern-action-preview:close)", ":q\<CR>")
    nmap <silent> <buffer> q <Plug>(fern-quit-or-close-preview)
endfunction

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

augroup fern-custom
    autocmd! *
    autocmd FileType fern call s:init_fern()
augroup END

function! s:fern_preview_init() abort
  nmap <buffer><expr>
        \ <Plug>(fern-my-preview-or-nop)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open:edit)\<C-w>p",
        \   "",
        \ )
  nmap <buffer><expr> j
        \ fern#smart#drawer(
        \   "j\<Plug>(fern-my-preview-or-nop)",
        \   "j",
        \ )
  nmap <buffer><expr> k
        \ fern#smart#drawer(
        \   "k\<Plug>(fern-my-preview-or-nop)",
        \   "k",
        \ )
endfunction

augroup my-fern-preview
  autocmd! *
  autocmd FileType fern call s:fern_preview_init()
augroup END

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
let g:undotree_WindowLayout=2
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
    g = { ":Ag<CR>", "Ag Search" },
}, { prefix = "<leader>" })
EOF

" Wilder
call wilder#setup({'modes': [':', '/', '?']})

call wilder#set_option('renderer', wilder#wildmenu_renderer(
  \ wilder#wildmenu_airline_theme({
  \   'highlighter': wilder#basic_highlighter(),
  \ })))
