" Catppuccin Mocha for Standard Vim
" Palette-driven: colours come from autoload/catppuccin/mocha.vim.
hi clear
if exists("syntax_on")
  syntax reset
endif

let s:palette = catppuccin#mocha#get()

function! s:hex(name) abort
  return s:palette[a:name][0]
endfunction

function! s:hi(group, fg, bg, ...) abort
  let l:cmd = 'hi ' . a:group
  if a:fg !=# ''
    let l:cmd .= ' guifg=' . s:hex(a:fg)
  endif
  if a:bg !=# ''
    let l:cmd .= ' guibg=' . s:hex(a:bg)
  endif
  if a:0 > 0 && a:1 !=# ''
    let l:cmd .= ' ' . a:1
  endif
  execute l:cmd
endfunction

" Core Mocha Palette Highlights
call s:hi('Normal', 'text', 'base', 'ctermbg=none')
call s:hi('NonText', 'surface2', '')
call s:hi('Comment', 'overlay0', '', 'cterm=italic gui=italic')
call s:hi('Constant', 'peach', '')
call s:hi('String', 'green', '')
call s:hi('Identifier', 'rosewater', '', 'cterm=none')
call s:hi('Function', 'blue', '')
call s:hi('Statement', 'mauve', '')
call s:hi('PreProc', 'yellow', '')
call s:hi('Type', 'sky', '')
call s:hi('Special', 'flamingo', '')
call s:hi('Underlined', 'blue', '', 'cterm=underline gui=underline')
call s:hi('Todo', 'crust', 'yellow')
call s:hi('LineNr', 'surface1', 'base')
call s:hi('CursorLineNr', 'lavender', 'base')
call s:hi('Visual', '', 'surface1')
call s:hi('Search', 'crust', 'yellow')
call s:hi('StatusLine', 'text', 'surface0')
call s:hi('StatusLineNC', 'overlay0', 'mantle')
call s:hi('VertSplit', 'surface1', 'base')

let g:colors_name = 'catppuccin_mocha'
