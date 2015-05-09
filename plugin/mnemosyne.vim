" Mnemosyne.vim - Mistress of Macros
" Author:       Rich Russon (flatcap) <rich@flatcap.org>
" Website:      https://flatcap.org
" Copyright:    2015 Richard Russon
" License:      GPLv3 <http://fsf.org/>
" Version:      1.0

" Set some default values
if (!exists ('g:mnemosyne_macro_file'))     | let g:mnemosyne_macro_file     = '~/.vim/macros.vim' | endif
if (!exists ('g:mnemosyne_magic_map_char')) | let g:mnemosyne_magic_map_char = 'a'                 | endif
if (!exists ('g:mnemosyne_max_macros'))     | let g:mnemosyne_max_macros     = 25                  | endif
if (!exists ('g:mnemosyne_register_list'))  | let g:mnemosyne_register_list  = 'abcdefghij'        | endif
if (!exists ('g:mnemosyne_show_help'))      | let g:mnemosyne_show_help      = 1                   | endif
if (!exists ('g:mnemosyne_show_labels'))    | let g:mnemosyne_show_labels    = 1                   | endif
if (!exists ('g:mnemosyne_split_vertical')) | let g:mnemosyne_split_vertical = 1                   | endif

let s:window_name = '__mnemosyne__'

function! s:set_registers()
	let @a = 'apple'
	let @b = 'banana'
	let @c = 'cherry'
	let @d = 'damson'
	let @e = 'elderberry'
endfunction

function! s:move_registers()
	let @f = @e
	let @e = @d
	let @d = @c
	let @c = @b
	let @b = @a
endfunction

function! s:create_mappings()
	nnoremap <buffer> <silent> q :call mnemosyne#CloseMacroWindow()<cr>
endfunction

function! s:populate_macro_window()
	call setline (1, '" Mnemosyne.vim - Mistress of Macros')
	let registers = split('abcdefghij', '\zs')
	let old_paste = &paste
	setlocal paste
	for i in registers
		execute 'normal! o' . i . "\t"
		let contents = getreg(i)
		if (len (contents) > 0)
			execute 'normal! "'.i.'p'
		endif
	endfor
	let &paste = old_paste
endfunction

function! s:find_window_number()
	let win_max = winnr ('$')
	for i in range (1, win_max)
		if (bufname(winbufnr(i)) == s:window_name)
			return i
		endif
	endfor

	return -1
endfunction


function! mnemosyne#ReadMacrosFromFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
endfunction

function! mnemosyne#SaveMacrosToFile(...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
endfunction


function! mnemosyne#OpenMacroWindow (...)
	let winnum = s:find_window_number()
	if (winnum >= 0)
		execute winnum . 'wincmd w'
		return
	endif

	let vert = (a:0 > 0) ? a:1 : g:mnemosyne_split_vertical

	let cmd = 'new ' . s:window_name
	if (vert == 1)
		let cmd = 'vertical ' . cmd
	endif
	execute cmd

	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal filetype=vim
	setlocal list

	call s:populate_macro_window()
	call s:create_mappings()
endfunction

function! mnemosyne#CloseMacroWindow()
	let bufnum = bufnr (s:window_name)
	if (bufnum >= 0)
		execute 'silent bwipeout ' . bufnum
	endif
endfunction

function! mnemosyne#ListMacros()
	let l:old_more = &l:more
	let &l:more = 1

	echohl MoreMsg
	echom 'Mnemosyne registers:'
	echohl none

	let registers = split('abcdefghij', '\zs')
	for i in registers
		let contents = getreg(i)
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let pinned = (i == 'f') ? '*' : ' '
		echom printf (' %s%s : %s', i, pinned, contents)
	endfor

	let &l:more = l:old_more
endfunction

function! mnemosyne#PinMacro (name, pin)
endfunction


map <F10> :call mnemosyne#CloseMacroWindow()<cr>
map <F11> :call mnemosyne#OpenMacroWindow(1)<cr>
map <F12> :call mnemosyne#ListMacros()<cr>

function! NumCompare (i1, i2)
	return a:i1 - a:i2
endfunction

let g:mnemosyne_registers = {
	\ 1  : 'apple',
	\ 2  : 'banana',
	\ 3  : 'cherry',
	\ 4  : 'damson',
	\ 5  : 'elderberry',
	\ 6  : 'fig',
	\ 7  : 'guava',
	\ 8  : 'hawthorn',
	\ 9  : 'ilama',
	\ 10 : 'jackfruit',
	\ 11 : 'kumquat',
	\ 12 : 'lemon',
	\ 13 : 'mango',
	\ 14 : 'nectarine',
	\ 15 : 'olive',
	\ 16 : 'papaya',
	\ 17 : 'quince',
	\ 18 : 'raspberry',
	\ 19 : 'strawberry',
	\ 20 : 'tangerine',
	\ 21 : 'ugli',
	\ 22 : 'vanilla',
	\ 23 : 'wolfberry',
	\ 24 : 'xigua',
	\ 25 : 'yew',
	\ 26 : 'ziziphus'
\ }

function! SetRegisters()

endfunction

" echo sort(keys(g:mnemosyne_registers), "NumCompare")
