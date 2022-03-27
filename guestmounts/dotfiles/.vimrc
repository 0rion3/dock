call plug#begin('~/.vim/plugged')
  Plug 'scrooloose/nerdcommenter'
call plug#end()

syn on
set anti
set nu

set termguicolors
set t_Co=256
set background=dark
set cursorline
colorscheme gruvbox


set hlsearch
set lazyredraw
set enc=utf-8
set fencs=ucs-bom,utf-8,default,latin1
set tabstop=2
set shiftwidth=2
set winaltkeys=no
set regexpengine=1

" No trash files
set nobackup
set nowritebackup
set noswapfile

autocmd VimEnter * set vb t_vb= "Disable visual and audio bell

"select all text
map <C-a> ggVG

"Encodings
set fileencodings=utf-8

" Folding
set foldmethod=indent
set foldlevel=100

"--------- FORMATTING AND CONTROLLING LINES OF TEXT
  set formatoptions=tcqnl1
    " t - textwidth
    " c - comments (plus leader -- see :help comments)
    " q - allogw 'gq' to work
    " n - numbered lists
    " l - Don't break words in the middle while using wordwrap
    " 2 - keep second line indent
    " 1 - single letter words on next line
    " r - (in mail) comment leader after

  " set linebreak
  set wrap " Soft word wrapping
  set lbr " only split lines when there's whitespace
  set breakindent " keep indentation when re-formatung and breaking lines

  " Fix backspace
  set backspace=2
  set backspace=indent,eol,start

  set textwidth=120 " this value will differ for plaintext, see below
  set colorcolumn=+1
  " Re-map default Vim indent to the external fmt utility (should work on Linux and BSD)
  map gq :%!fmt -w 120<CR>
  " set noai " no auto-indent when pasting, not sure I need it.
"------ END OF / FORMATTING AND CONTROLLING LINES OF TEXT
"
""--------- BLOCK setting custom filetypes ---
  filetype plugin on

  " All files without extentions that don't start with #!/
  " are to be treated as plaintext files.
  autocmd BufNewFile,BufRead * if (expand('%:t') !~ '\.' && getline(1) =~ '^/\!#') | setf text | endif

  " By default, vim thinks .md is Modula-2.
  autocmd BufNewFile,BufReadPost *.md set filetype=markdown

  let b:is_bash = 1 " Make vim treat .sh files as bash
  autocmd FileType * set textwidth=120
  autocmd FileType * map gq :%!fmt -w 80<CR>
  autocmd FileType text set textwidth=80 " not comfortable to read them otherwise
  autocmd FileType text map gq :%!fmt -w 80<CR>

  if $NO_SPELLCHECK != 1
    autocmd BufRead,BufNewFile *.erb setlocal spell
    autocmd BufRead,BufNewFile *.haml setlocal spell
    autocmd FileType markdown setlocal spell
    autocmd FileType text setlocal spell
    autocmd FileType gitcommit setlocal spell
  endif
"----------END OF / setting cystom filetypes ---

"clean highlighting of last search
nmap <F3> :nohlsearch<CR>
imap <F3> <Esc>:nohlsearch<CR>
vmap <F3> <Esc>:nohlsearch<CR>gv

" Commit message colors
hi def link gitcommitSummary Normal
hi def link gitcommitBlank Normal

" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

" Close buffer when tab is closed
set nohidden

" Show statusline everywhere
set laststatus=2

let showmarks_include = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

" Display extra whitespace
let listchars="tab:»·,trail:·,nbsp:⎵"

map <Leader>f ysiw

" Mappings for splits
map <C-j> <C-W><C-J>
map <C-k> <C-W><C-K>
map <C-i> <C-W><C-L>
map <C-l> <C-W><C-H>
map <F2> :wincmd w<CR>
map <C-j> :wincmd h<CR>
map <C-k> :wincmd j<CR>
map <C-i> :wincmd k<CR>
map <C-l> :wincmd l<CR>

" Resizing splits
map <silent> <C-Left> :vertical resize -5<CR>
map <silent> <C-Up> :resize +5<CR>
map <silent> <C-Down> :resize -5<CR>
map <silent> <C-Right> :vertical resize +5<CR>

" Move 10 lines up and down
map <S-l> 10-
map <S-k> 10+

" *** EasyAlign plugin mappings
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" This line should problably be at the end of file,
" or plugins might change it.
let mapleader = ","
