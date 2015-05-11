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

function! WindowTogglePinned()
	let line = getline('.')
	let line = substitute (line, '\v^(\i)\**	(.*)', '\1*\2', '')
	call setline (1, '" Mnemosyne.vim - Mistress of Macros')
endfunction

function! s:create_mappings()
	nnoremap <buffer> <silent> q :call CloseMacroWindow()<cr>
	nnoremap <buffer> <silent> \p :call WindowTogglePinned()<cr>
endfunction

function! s:populate_macro_window()
	let old_paste = &paste
	setlocal paste
	execute '%d'

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


function! g:SyncRegistersToVar()
	let num = len (g:mnemosyne_registers)

	let key_list = sort (keys (g:mnemosyne_registers), "s:num_compare")

	for i in range (1, num)
		if (i > len (g:mnemosyne_register_list))
			break
		endif

		let reg = g:mnemosyne_register_list[i-1]
		let reg_idx = key_list[i-1]
		let macro = getreg (reg)
		let g:mnemosyne_registers[reg_idx].macro = macro
	endfor
endfunction

function! g:MoveRegisters()
	let prev = ''

	call SyncRegistersToVar()

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

function! g:SetRegisters()
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

function! g:ReadMacrosFromFile (...)
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

function! g:SaveMacrosToFile (...)
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


function! g:OpenMacroWindow (...)
	let winnum = s:find_window_number()
	if (winnum >= 0)
		execute winnum . 'wincmd w'
		return
	endif

	let bufnum = bufnr ('%')
	let cursor = getpos ('.')

	let mod_buf = bufnr (s:window_name)
	if (mod_buf < 0)
		execute 'silent enew'
		execute 'silent file ' . s:window_name
	else
		execute 'silent ' . mod_buf . 'buffer'
	endif

	let w:return_buffer = bufnum
	let w:return_cursor = cursor

	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal nobuflisted
	setlocal noswapfile
	setlocal cursorline
	setlocal filetype=vim
	" setlocal list

	setlocal modifiable
	call s:populate_macro_window()
	setlocal nomodifiable

	call s:create_mappings()

	normal 2G
endfunction

function! g:CloseMacroWindow()
	let winnum = s:find_window_number()
	if (winnum < 0)
		return
	endif

	let this_win = winnr()
	if (winnum != this_win)
		execute winnum . 'wincmd w'
	endif

	if (exists ('w:return_buffer'))
		" execute 'silent ' . w:return_buffer . 'buffer'
		execute w:return_buffer . 'buffer'
	endif

	if (exists ('w:return_cursor'))
		call setpos ('.', w:return_cursor)
	endif

	if (this_win != winnr())
		execute this_win . 'wincmd w'
	endif
endfunction

function! g:ToggleMacroWindow()
	let win_num = s:find_window_number()
	if (win_num >= 0)
		call CloseMacroWindow()
	else
		call OpenMacroWindow()
	endif
endfunction

function! g:ShowRegisters()
	call SyncRegistersToVar()

	let num = len(g:mnemosyne_register_list)
	echo 'Mnemosyne registers (' . num . ' entries):'
	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		if (i >= num)
			break
		endif
		let name = g:mnemosyne_register_list[i]
		let contents = g:mnemosyne_registers[i].macro
		let contents = substitute (contents, nr2char(10), '^J', 'g')
		let contents = substitute (contents, nr2char(13), '^M', 'g')
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let flags = (exists ('g:mnemosyne_registers[i].pinned')) ? '*' : ' '
		echo printf ('  %s%s : %s', name, flags, contents)
	endfor
endfunction

function! g:ShowAll()
	call SyncRegistersToVar()

	echo 'Mnemosyne registers (' . len(g:mnemosyne_registers) . ' entries):'
	for i in sort (keys (g:mnemosyne_registers), 's:num_compare')
		let name = (i < len(g:mnemosyne_register_list)) ? g:mnemosyne_register_list[i] : '-'
		let contents = g:mnemosyne_registers[i].macro
		let contents = substitute (contents, nr2char(10), '^J', 'g')
		let contents = substitute (contents, nr2char(13), '^M', 'g')
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let flags = (exists ('g:mnemosyne_registers[i].pinned')) ? '*' : ' '
		echo printf ('  %s%s : %s', name, flags, contents)
	endfor
endfunction

function! g:PinMacro (name, pin)
	let i = stridx (g:mnemosyne_register_list, a:name)
	if (i < 0)
		let i = a:name
	endif

	if (!exists ('g:mnemosyne_registers[i]'))
		echohl error
		echom 'NO MATCH'
		echohl none
		return
	endif
	echom 'MATCH'
	echo g:mnemosyne_registers[i]
	if (a:pin)
		let g:mnemosyne_registers[i].pinned = 1
	else
		unlet g:mnemosyne_registers[i].pinned
	endif
	echo g:mnemosyne_registers[i]
endfunction


function! g:ClearRegisters()
	for i in range (26)
		let reg = nr2char (char2nr ('a')+i)
		call setreg (reg, '')
	endfor
endfunction


call ReadMacrosFromFile()

nnoremap <silent> <leader>mc :call CloseMacroWindow()<cr>
nnoremap <silent> <leader>ml :call ShowRegisters()<cr>
nnoremap <silent> <leader>mL :call ShowAll()<cr>
nnoremap <silent> <leader>mm :call MoveRegisters()<cr>
nnoremap <silent> <leader>mo :call OpenMacroWindow()<cr>
nnoremap <silent> <leader>mr :call ReadMacrosFromFile()<cr>
nnoremap <silent> <leader>ms :call SaveMacrosToFile()<cr>
nnoremap <silent> <leader>mt :call ToggleMacroWindow()<cr>
nnoremap <silent> <leader>mv :call SyncRegistersToVar()<cr>

nnoremap <silent> <F12> :update<cr>:source plugin/mnemosyne.vim<cr>

" nnoremap <silent> qa :call MoveRegisters()<cr>qa
" nnoremap <silent> q  q:call SyncRegistersToVar()<cr>
