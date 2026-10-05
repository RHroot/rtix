" ─────────────────────────────────────────────────────────────────────────────
" 1. CORE
" ─────────────────────────────────────────────────────────────────────────────
set nocompatible
filetype plugin indent on
syntax on

let mapleader = " "
let maplocalleader = "\\"

" Detect best clipboard option for your system
if has('clipboard')
  if has('unnamedplus')
    set clipboard=unnamedplus
  elseif has('unnamed')
    set clipboard=unnamed
  elseif has('macunix')
    set clipboard=unnamed
  endif
endif

" ─────────────────────────────────────────────────────────────────────────────
" 2. ENCODING
" ─────────────────────────────────────────────────────────────────────────────
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,latin1

" ─────────────────────────────────────────────────────────────────────────────
" 4. UI & APPEARANCE
" ─────────────────────────────────────────────────────────────────────────────
set termguicolors
colorscheme unokai

function! s:DarkerBg() abort
  highlight Normal       guibg=#0d0d0d  ctermbg=232
  highlight NormalNC     guibg=#0d0d0d  ctermbg=232
  highlight SignColumn   guibg=#0d0d0d  ctermbg=232
  highlight EndOfBuffer  guibg=#0d0d0d  guifg=#222228
  highlight VertSplit    guibg=#0d0d0d  guifg=#2a2a35 ctermbg=232 ctermfg=236
  highlight Folded       guibg=#131318  guifg=#6a6a7a
  highlight FoldColumn   guibg=#0d0d0d  guifg=#3a3a4a
endfunction

augroup darker_bg
  autocmd!
  autocmd ColorScheme * call s:DarkerBg()
augroup END
call s:DarkerBg()

set number
set relativenumber
set cursorline
set cursorcolumn
set signcolumn=yes
set showmode
set list
set listchars=tab:»\ ,trail:·,nbsp:␣,extends:›,precedes:‹
set showbreak=↪\
set scrolloff=8
set sidescrolloff=5
set sidescroll=1
set mouse=a
set laststatus=2
set showcmd
set display=lastline

" ─────────────────────────────────────────────────────────────────────────────
" 5. STATUSLINE
" ─────────────────────────────────────────────────────────────────────────────
let s:modes = {
      \ 'n':      'NORMAL',  'no':     'N·OP',   'nov':    'N·OP',
      \ 'v':      'VISUAL',  'V':      'V·LINE',  "\<C-v>": 'V·BLOC',
      \ 's':      'SELECT',  'S':      'S·LINE',  "\<C-s>": 'S·BLOC',
      \ 'i':      'INSERT',  'ic':     'INSERT',  'ix':     'INSERT',
      \ 'R':      'REPLACE', 'Rv':     'V·REPL',
      \ 'c':      'COMMAND', 'cv':     'EX',      'ce':     'EX',
      \ 'r':      'PROMPT',  'rm':     'MORE',    'r?':     'CONFIRM',
      \ '!':      'SHELL',   't':      'TERM',
      \ }

function! StatuslineMode() abort
  return get(s:modes, mode(), mode())
endfunction

function! StatuslineGit() abort
  " Reads .git/HEAD directly — no plugin, no external process
  if !exists('b:_git_branch') || b:_git_mtime != getftime(expand('%'))
    let b:_git_mtime = getftime(expand('%'))
    let b:_git_branch = ''
    let head = findfile('.git/HEAD', expand('%:p:h') . ';')
    if !empty(head)
      let lines = readfile(head, '', 1)
      if !empty(lines)
        let b:_git_branch = ' ' . substitute(lines[0], 'ref: refs/heads/', '', '') . ' '
      endif
    endif
  endif
  return b:_git_branch
endfunction

highlight SLMode    guibg=#5f87d7 guifg=#0d0d0d gui=bold ctermbg=68  ctermfg=232 cterm=bold
highlight SLGit     guibg=#252535 guifg=#a0a0c0 gui=none ctermbg=236 ctermfg=146
highlight SLFile    guibg=#1a1a26 guifg=#c8c8d8 gui=none ctermbg=235 ctermfg=252
highlight SLMid     guibg=#0d0d0d guifg=#0d0d0d gui=none ctermbg=232 ctermfg=232
highlight SLInfo    guibg=#1a1a26 guifg=#808090 gui=none ctermbg=235 ctermfg=244
highlight SLPos     guibg=#252535 guifg=#c8c8d8 gui=none ctermbg=236 ctermfg=252
highlight SLPct     guibg=#5f87d7 guifg=#0d0d0d gui=bold ctermbg=68  ctermfg=232 cterm=bold
highlight SLWarn    guibg=#cc5533 guifg=#ffffff  gui=bold ctermbg=166 ctermfg=255 cterm=bold

set statusline=\ |
set statusline+=%#SLMode#\ %{StatuslineMode()}\ |
set statusline+=%#SLGit#%{StatuslineGit()}\ |
set statusline+=%#SLFile#\ %f%{&modified?'\ ●':''}%{&readonly?'\ ':''}\ |
set statusline+=%#SLWarn#%{&paste?'\ PASTE\ ':''}\ |
set statusline+=%#SLMid#%=\ |
set statusline+=%#SLInfo#\ %{&fileformat}\ │\ %{&fenc?&fenc:&enc}\ │\ %{&ft!=''?&ft:'no\ ft'}\ |
set statusline+=%#SLPos#\ %l:%c\ |
set statusline+=%#SLPct#\ %p%%\ |

" ─────────────────────────────────────────────────────────────────────────────
" 6. EDITING BEHAVIOUR
" ─────────────────────────────────────────────────────────────────────────────
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set autoindent
set shiftround

set formatoptions=crqjl

set wrap
set linebreak
set breakindent
set breakindentopt=shift:2

set hidden
set splitbelow
set splitright
set nrformats-=octal
set virtualedit=block

set spell spelllang=en_us
nnoremap <leader>sp :setlocal spell!<CR>

set conceallevel=2 concealcursor=nc
set diffopt+=internal,filler,iwhite,algorithm:histogram

" ─────────────────────────────────────────────────────────────────────────────
" 7. SEARCH & NAVIGATION
" ─────────────────────────────────────────────────────────────────────────────
set ignorecase
set smartcase
set incsearch
set hlsearch
set jumpoptions=stack

set wildmenu
set wildmode=longest:full,full
set wildoptions=pum
set wildignorecase
set wildignore=*.o,*.obj,*.pyc,*.class,*.swp,*~

set path+=**

set completeopt=menuone,noselect,noinsert

" ─────────────────────────────────────────────────────────────────────────────
" 9. UNDO / SWAP / BACKUP
" ─────────────────────────────────────────────────────────────────────────────
set nobackup
set undofile
set noswapfile
set nowritebackup
set undolevels=1000
set undoreload=10000

let s:undodir = expand('~/.vim/undodir')
if !isdirectory(s:undodir) | call mkdir(s:undodir, 'p', 0700) | endif
let &undodir = s:undodir

set updatetime=1000
set timeout timeoutlen=500
set ttimeout ttimeoutlen=10

" Persist jumps, marks, registers across sessions
set viminfo='100,<50,s10,h,!

" ─────────────────────────────────────────────────────────────────────────────
" 10. AUTOCOMMANDS
" ─────────────────────────────────────────────────────────────────────────────
" ── Trailing whitespace ────────────────────────────────────────────────────
highlight TrailingWS ctermbg=red guibg=#cc3333
augroup trailing_ws
  autocmd!
  autocmd BufEnter    * if &modifiable | call matchadd('TrailingWS', '\s\+$') | endif
  autocmd BufWritePre * if &modifiable | silent! %s/\s\+$//e | endif
augroup END

" ── Return to last edited position ────────────────────────────────────────
augroup last_position
  autocmd!
  autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &filetype !~# 'commit'
        \ |   execute 'normal! g`"'
        \ | endif
augroup END

" ── Auto-equalise splits on resize ────────────────────────────────────────
augroup auto_resize
  autocmd!
  autocmd VimResized * wincmd =
augroup END

  " ── Per-filetype tweaks ────────────────────────────────────────────────────
augroup filetype_settings
    autocmd!
    autocmd FileType python    setlocal tabstop=4 shiftwidth=4 softtabstop=4
    autocmd FileType go        setlocal tabstop=4 shiftwidth=4 noexpandtab
    autocmd FileType make      setlocal noexpandtab
    autocmd FileType markdown  setlocal wrap linebreak spell
    autocmd FileType gitcommit setlocal spell textwidth=72 colorcolumn=73
    autocmd FileType qf,help,man setlocal nospell nolist
augroup END

  " ─────────────────────────────────────────────────────────────────────────────
  " 11. KEYMAPS
  " ─────────────────────────────────────────────────────────────────────────────
  " ── Convenience ────────────────────────────────────────────────────────────
nnoremap ; :
xnoremap ; :
inoremap <C-c> <Esc>
cnoremap <C-c> <C-c>
vnoremap <C-c> <Esc>

nnoremap <Esc>   :nohlsearch<CR>
nnoremap <C-c>   :nohlsearch<CR>

" ── Save / quit ────────────────────────────────────────────────────────────
nnoremap <leader>w  :write<CR>
nnoremap <leader>q  :quit<CR>
nnoremap <leader>Q  :qall!<CR>
nnoremap <leader>so :update<CR>:source %<CR>
nnoremap <leader>si :source $MYVIMRC<CR>

" ── Files & buffers ────────────────────────────────────────────────────────
nnoremap <leader>e  :Lexplore<CR>
nnoremap <leader>E  :Ex<CR>
nnoremap <leader>bc :enew<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bl :ls<CR>:b<Space>

" ── Window navigation ──────────────────────────────────────────────────────
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ── Window resizing ────────────────────────────────────────────────────────
nnoremap <C-Up>    :resize +2<CR>
nnoremap <C-Down>  :resize -2<CR>
nnoremap <C-Left>  :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" ── Editing ────────────────────────────────────────────────────────────────
" Move selected lines up / down and re-indent
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Join without moving the cursor
nnoremap J mzJ`z

" Centre the screen on common jumps
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n     nzzzv
nnoremap N     Nzzzv
nnoremap g;    g;zz
nnoremap g,    g,zz
nnoremap %     %zz

" Paste over selection without clobbering the unnamed register
vnoremap <leader>P "_dP

" Select the text that was last pasted (mirrors gv for yanks)
nnoremap gp `[v`]

" ── Terminal ───────────────────────────────────────────────────────────────
nnoremap <leader>t  :terminal<CR>
nnoremap <leader>tv :vertical terminal<CR>
tnoremap <Esc>      <C-\><C-n>
tnoremap <C-h>      <C-\><C-n><C-w>h
tnoremap <C-j>      <C-\><C-n><C-w>j
tnoremap <C-k>      <C-\><C-n><C-w>k
tnoremap <C-l>      <C-\><C-n><C-w>l

" ── Quickfix ───────────────────────────────────────────────────────────────
nnoremap <leader>co :copen<CR>
nnoremap <leader>cc :cclose<CR>
nnoremap <leader>cn :cnext<CR>zz
nnoremap <leader>cp :cprevious<CR>zz

" ─────────────────────────────────────────────────────────────────────────────
" 12. YANK HIGHLIGHT
" ─────────────────────────────────────────────────────────────────────────────
highlight YankFlash guibg=#e5c07b guifg=#1e1e2e gui=bold ctermbg=214 ctermfg=232 cterm=bold

augroup yank_highlight
    autocmd!
    autocmd TextYankPost * call s:FlashYank()
augroup END

function! s:FlashYank() abort
    if v:event.operator !=# 'y' | return | endif
    silent! call matchdelete(get(s:, '_ym', -1))

    let positions = []
    let start = getpos("'[")
    let end   = getpos("']")
    for lnum in range(start[1], end[1])
        let col  = (lnum == start[1]) ? start[2] : 1
        let cend = (lnum == end[1])   ? end[2]   : strchars(getline(lnum)) + 1
        let len  = cend - col
        if len > 0 | call add(positions, [lnum, col, len]) | endif
    endfor

    if empty(positions) | return | endif
    let s:_ym = matchaddpos('YankFlash', positions, 10, -1)
    call timer_start(100, {-> s:YankClear()})
endfunction

function! s:YankClear() abort
    silent! call matchdelete(get(s:, '_ym', -1))
    silent! unlet s:_ym
endfunction

" For GVim - ensure proper GUI colors
if has("gui_running")
  set guifont=Monospace\ 18  " Adjust to your preference
  set guioptions-=T           " Remove toolbar
  set guioptions-=m           " Remove menu bar
  set guioptions-=r           " Remove right scrollbar
  set guioptions-=L           " Remove left scrollbar
  set guiheadroom=0
endif

" Ensure termguicolors works in terminal Vim too
if !has("gui_running") && has("termguicolors")
  set termguicolors
endif
