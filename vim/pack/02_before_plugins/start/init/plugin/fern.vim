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

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END
