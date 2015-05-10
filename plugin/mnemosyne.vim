" Mnemosyne.vim - Mistress of Macros
" Author:       Rich Russon (flatcap) <rich@flatcap.org>
" Website:      https://flatcap.org
" Copyright:    2015 Richard Russon
" License:      GPLv3 <http://fsf.org/>
" Version:      1.0

" if (exists ('g:loaded_mnemosyne') || &cp || (v:version < 700))
" 	finish
" endif
" let g:loaded_mnemosyne = 1

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

function! s:create_mappings()
	nnoremap <buffer> <silent> q :call CloseMacroWindow()<cr>
endfunction

function! s:populate_macro_window()
	let old_paste = &paste
	setlocal paste

	call setline (1, '" Mnemosyne.vim - Mistress of Macros')

	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		let name = (i < len(g:mnemosyne_register_list)) ? g:mnemosyne_register_list[i] : '-'
		if (exists ('g:mnemosyne_registers[i].pinned'))
			let name .= '*'
		endif
		execute 'normal! o' . name . "\t"
		let @" = g:mnemosyne_registers[i].macro
		if (len (@") > 0)
			execute 'normal! ""p'
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


function! MoveRegisters()
	let prev = ''

	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		if (exists ('g:mnemosyne_registers[i].pinned'))
			continue
		endif

		let current = g:mnemosyne_registers[i].macro
		let g:mnemosyne_registers[i].macro = prev
		let prev = current
	endfor

	call SetRegisters()
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
		let macro = g:mnemosyne_registers[reg_idx].macro
		if (len (reg) == 1)
			call setreg (reg, macro)
		endif
	endfor
endfunction

function! ReadMacrosFromFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let file = expand (file)
	let list = readfile (file)

	let num = len (list)
	let index = 0
	for i in range (num)
		let line = list[i]
		if (line =~ '^\s*"')
			continue
		endif

		let flags = substitute (line, '\t.*', '', '')
		let macro = substitute (line, '^.\{-\}\t', '', '')

		let entry = { 'macro' : macro }

		if (flags =~? 'p')
			let entry.pinned = 1
			" echo entry
		endif

		let g:mnemosyne_registers[index] = entry
		let index += 1
	endfor
	call SetRegisters()
endfunction

function! SaveMacrosToFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file

	let list = [
		\ '" Mnemosyne.vim - Mistress of Macros',
		\ '" https://github.com/flatcap/vim-mnemosyne'
	\ ]

	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		let list += [ "\t" . g:mnemosyne_registers[i] ]
	endfor

	let file = expand (file)
	call writefile (list, file)
endfunction


function! OpenMacroWindow (...)
	let winnum = s:find_window_number()
	if (winnum >= 0)
		execute winnum . 'wincmd w'
		return
	endif

	let vert = (a:0 > 0) ? a:1 : g:mnemosyne_split_vertical

	let cmd = 'silent new ' . s:window_name
	if (vert == 1)
		let cmd = 'vertical ' . cmd
	endif
	execute cmd

	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal filetype=vim
	" setlocal list

	call s:populate_macro_window()
	call s:create_mappings()

	normal 2G
endfunction

function! CloseMacroWindow()
	let bufnum = bufnr (s:window_name)
	if (bufnum >= 0)
		execute 'silent bwipeout ' . bufnum
	endif
endfunction

function! ToggleMacroWindow()
	let win_num = s:find_window_number()
	if (win_num < 0)
		call OpenMacroWindow()
	else
		call CloseMacroWindow()
	endif
endfunction

function! ShowRegisters()
	echo 'Mnemosyne registers (' . len(g:mnemosyne_registers) . ' entries):'

	" XXX sync registers to variable

	let registers = split (g:mnemosyne_register_list, '\zs')
	for i in registers
		let contents = getreg (i)
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		echom printf ('  %s : %s', i, contents)
	endfor
endfunction

function! ShowAll()
	echo 'Mnemosyne registers (' . len(g:mnemosyne_registers) . ' entries):'

	" XXX sync registers to variable

	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		let name = (i < len(g:mnemosyne_register_list)) ? g:mnemosyne_register_list[i] : '-'
		let contents = g:mnemosyne_registers[i].macro
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let flags = (exists ('g:mnemosyne_registers[i].pinned')) ? '*' : ' '
		echo printf ('  %s%s : %s', name, flags, contents)
	endfor
endfunction

function! PinMacro (name, pin)
endfunction


function! ClearRegisters()
	for i in range (26)
		let reg = nr2char (char2nr ('a')+i)
		call setreg (reg, '')
	endfor
endfunction


call ReadMacrosFromFile()

nnoremap <silent> <leader>mc :call CloseMacroWindow()<cr>
nnoremap <silent> <leader>ml :call ShowAll()<cr>
nnoremap <silent> <leader>mm :call MoveRegisters()<cr>
nnoremap <silent> <leader>mo :call OpenMacroWindow()<cr>
nnoremap <silent> <leader>mr :call ReadMacrosFromFile()<cr>
nnoremap <silent> <leader>ms :call SaveMacrosToFile()<cr>
nnoremap <silent> <leader>mt :call ToggleMacroWindow()<cr>

nnoremap <silent> <F12> :update<cr>:source plugin/mnemosyne.vim<cr>

