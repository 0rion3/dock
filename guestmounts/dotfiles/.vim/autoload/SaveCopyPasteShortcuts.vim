" CTRL-X and SHIFT-Del are Cut
vnoremap <C-X>   "+x
vnoremap <S-Del> "+x

" CTRL-C and CTRL-Insert are Copy
vnoremap <C-C>      "+y
vnoremap <C-Insert> "+y
vnoremap <D-C>      "+y

" CTRL-V and SHIFT-Insert are Paste
map <C-V>         "+gP
map <D-V>         "+gP
map <S-Insert>    "+gP

cmap <C-V>        <C-R>+
cmap <D-V>        <D-R>+
cmap <S-Insert>   <C-R>+

" Map saving to Cmd+S or Ctrl+S
map <D-s> :w<CR>
map <C-s> :w<CR>
map <F12> :w<CR>
inoremap <D-s> <Esc>:w<CR>
inoremap <C-s> <Esc>:w<CR>
inoremap <F12> <Esc>:w<CR>

function! Paste()
  set paste
  "execute 'startinsert'
  visual "+gP
  set nopaste
endfunction
