" Mnemosyne.vim - Mistress of Macros
" Author:       Rich Russon (flatcap) <rich@flatcap.org>
" Website:      https://flatcap.org
" Copyright:    2015 Richard Russon
" License:      GPLv3 <http://fsf.org/>
" Version:      1.0

let s:window_name = '__mnemosyne__'

" Set some default values
if (!exists ('g:mnemosyne_macro_file'))     | let g:mnemosyne_macro_file     = '~/.vim/macros.vim' | endif
if (!exists ('g:mnemosyne_magic_map_char')) | let g:mnemosyne_magic_map_char = 'a'                 | endif
if (!exists ('g:mnemosyne_max_macros'))     | let g:mnemosyne_max_macros     = 20                  | endif
if (!exists ('g:mnemosyne_register_list'))  | let g:mnemosyne_register_list  = 'abcdefghij'        | endif
if (!exists ('g:mnemosyne_show_help'))      | let g:mnemosyne_show_help      = 1                   | endif
if (!exists ('g:mnemosyne_show_labels'))    | let g:mnemosyne_show_labels    = 1                   | endif
if (!exists ('g:mnemosyne_split_vertical')) | let g:mnemosyne_split_vertical = 1                   | endif

let g:mnemosyne_registers = {}

function! s:num_compare (i1, i2)
	return a:i1 - a:i2
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
	let registers = split ('abcdefghij', '\zs')
	let old_paste = &paste
	setlocal paste
	for i in registers
		execute 'normal! o' . i . "\t"
		let contents = getreg (i)
		if (len (contents) > 0)
			execute 'normal! "'.i.'p'
		endif
	endfor
	let &paste = old_paste
endfunction

function! s:find_window_number()
	let win_max = winnr ('$')
	for i in range (1, win_max)
		if (bufname (winbufnr (i)) == s:window_name)
			return i
		endif
	endfor

	return -1
endfunction


function! SetRegisters()
	let num = len (g:mnemosyne_registers)

	let key_list = sort (keys (g:mnemosyne_registers), "s:num_compare")

	for i in range (1, num)
		if (i <= len (g:mnemosyne_register_list))
			let reg = g:mnemosyne_register_list[i-1]
		elseif (i <= g:mnemosyne_max_macros)
			let reg = 'unnamed'
		else
			let reg = 'lost'
		endif
		let reg_idx = key_list[i-1]
		let macro = g:mnemosyne_registers[reg_idx]
		if (len (reg) == 1)
			call setreg (reg, macro)
		endif
		echom printf ("%d : %s : %s", i, reg, macro)
		if ( (i == g:mnemosyne_max_macros) || (i == len (g:mnemosyne_register_list)))
			echom '-------------------'
		endif
	endfor

endfunction

function! mnemosyne#ReadMacrosFromFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let file = expand (file)
	let list = readfile (file)

	let num = len (list)
	for i in range (num)
		let g:mnemosyne_registers[i] = list[i]
		" let reg = nr2char (char2nr ('a')+i)
		" call setreg (reg, list[i])
	endfor
	call SetRegisters()
endfunction

function! mnemosyne#SaveMacrosToFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let list = []

	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		let list += [ g:mnemosyne_registers[i] ]
	endfor

	let file = expand (file)
	call writefile (list, file)
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

	let registers = split ('abcdefghij', '\zs')
	for i in registers
		let contents = getreg (i)
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let pinned = (i == 'f') ? '*' : ' '
		echom printf (' %s%s : %s', i, pinned, contents)
	endfor

	let &l:more = l:old_more
endfunction

function! mnemosyne#PinMacro (name, pin)
endfunction


function! ClearRegisters()
	for i in range (26)
		let reg = nr2char (char2nr ('a')+i)
		call setreg (reg, '')
	endfor
endfunction


call mnemosyne#ReadMacrosFromFile()

map <F7>  :call mnemosyne#ReadMacrosFromFile()<cr>
map <F8>  :call mnemosyne#SaveMacrosToFile()<cr>
map <F9>  :call SetRegisters()<cr>
map <F10> :call mnemosyne#CloseMacroWindow()<cr>
map <F11> :call mnemosyne#OpenMacroWindow (1)<cr>
map <F12> :call mnemosyne#ListMacros()<cr>

