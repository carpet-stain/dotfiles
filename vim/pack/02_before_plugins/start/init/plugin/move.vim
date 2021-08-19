" Move line up and down in normal mode and visual mode
noremap ∆ <Esc>:m .+1<CR>
noremap ˚ <Esc>:m .-2<CR>
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv
