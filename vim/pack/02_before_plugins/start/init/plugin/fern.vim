" Disable netrw.
let g:loaded_netrw  = 1
let g:loaded_netrwPlugin = 1
let g:loaded_netrwSettings = 1
let g:loaded_netrwFileHandlers = 1

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
