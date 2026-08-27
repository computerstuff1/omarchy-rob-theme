" Catppuccin Mocha for Standard Vim
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "catppuccin_mocha"

" Core Mocha Palette Highlights
hi Normal ctermbg=none guibg=#1e1e2e guifg=#cdd6f4
hi NonText guifg=#585b70
hi Comment guifg=#6c7086 cterm=italic gui=italic
hi Constant guifg=#fab387
hi String guifg=#a6e3a1
hi Identifier guifg=#f5e0dc cterm=none
hi Function guifg=#89b4fa
hi Statement guifg=#cba6f7
hi PreProc guifg=#f9e2af
hi Type guifg=#89dceb
hi Special guifg=#f2cdcd
hi Underlined guifg=#89b4fa cterm=underline gui=underline
hi Todo guifg=#11111b guibg=#f9e2af
hi LineNr guifg=#45475a guibg=#1e1e2e
hi CursorLineNr guifg=#b4befe guibg=#1e1e2e
hi Visual guibg=#45475a
hi Search guifg=#11111b guibg=#f9e2af
hi StatusLine guifg=#cdd6f4 guibg=#313244
hi StatusLineNC guifg=#6c7086 guibg=#181825
hi VertSplit guifg=#45475a guibg=#1e1e2e
