" ==========================================================
" Vim Configuration for Development
" ==========================================================

set nocompatible

" ---------------------------------------------
" Auto-install vim-plug
" ---------------------------------------------
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" ---------------------------------------------
" Plugin Management (vim-plug)
" ---------------------------------------------
call plug#begin('~/.vim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dense-analysis/ale'
Plug 'rust-lang/rust.vim'
Plug 'preservim/vim-markdown'
Plug 'JuliaEditorSupport/julia-vim'
Plug 'quarto-dev/quarto-vim'
Plug 'jpalardy/vim-slime'
call plug#end()

" ---------------------------------------------
" General
" ---------------------------------------------
set number
set relativenumber
set autoindent
set backspace=indent,eol,start
set hlsearch
set incsearch
set showmatch
set showcmd
set encoding=utf-8
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set maxmempattern=2000000
set mouse=a

" Persistent undo
set undofile
set undodir=~/.vim/undodir

" Clipboard (only when display is available)
if has('unnamedplus') && !empty($DISPLAY)
  set clipboard=unnamedplus
endif

" ---------------------------------------------
" Theme
" ---------------------------------------------
syntax enable
set background=dark

" ---------------------------------------------
" Filetype Settings
" ---------------------------------------------
if has("autocmd")
    filetype plugin indent on

    augroup vimrc_filetypes
        autocmd!
        autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

        autocmd FileType python setlocal sw=4 sts=4 et textwidth=88 colorcolumn=88
        autocmd FileType cpp,cuda setlocal sw=4 sts=4 et textwidth=100 colorcolumn=100
        autocmd FileType c setlocal sw=4 sts=4 et textwidth=100 colorcolumn=100
        autocmd FileType r setlocal sw=2 sts=2 et
        autocmd FileType julia setlocal sw=4 sts=4 et
        autocmd FileType quarto setlocal sw=4 sts=4 et spell textwidth=80 colorcolumn=80
    augroup END
endif

" ---------------------------------------------
" Abbreviations
" ---------------------------------------------
iabbrev <expr> me::
\ "# Created\n" .
\ "Author: Yonghun Suh\n" .
\ "Date: " . strftime("%B %d, %Y") . "\n" .
\ "License: MIT\n\n"

" ---------------------------------------------
" Airline
" ---------------------------------------------
let g:airline_powerline_fonts = 1
let g:airline_theme = "seoul256"

" ---------------------------------------------
" Markdown
" ---------------------------------------------
let g:vim_markdown_folding_disabled = 1

" ---------------------------------------------
" ALE (LSP + Linting + Fixing)
" ---------------------------------------------
let g:ale_completion_enabled = 1
set omnifunc=ale#completion#OmniFunc

let g:ale_linters = {
\  'python': ['pyright'],
\  'cpp': ['clangd'],
\  'c': ['clangd'],
\  'cuda': ['clangd'],
\  'rust': ['analyzer'],
\  'julia': ['languageserver'],
\  'r': ['languageserver'],
\}

let g:ale_fixers = {
\  'python': ['black'],
\  'cpp': ['clang-format'],
\  'c': ['clang-format'],
\}

" Auto-fix on save
let g:ale_fix_on_save = 1

" Tab completion in insert mode
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" LSP navigation
nnoremap <silent> gd :ALEGoToDefinition<CR>
nnoremap <silent> K :ALEHover<CR>
nnoremap <silent> gr :ALEFindReferences<CR>
nnoremap <silent> <leader>rn :ALERename<CR>
nnoremap <silent> [d :ALEPrevious<CR>
nnoremap <silent> ]d :ALENext<CR>

" ---------------------------------------------
" Vim-Slime (tmux integration)
" ---------------------------------------------
let g:slime_target = "tmux"
let g:slime_paste_file = "$HOME/.slime_paste"
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}
let g:slime_dont_ask_default = 1
