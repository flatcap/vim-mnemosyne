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

" Set some default values
if (!exists ('g:mnemosyne_macro_file'))     | let g:mnemosyne_macro_file     = '~/.vim/macros.vim' | endif
if (!exists ('g:mnemosyne_max_macros'))     | let g:mnemosyne_max_macros     = 15                  | endif
if (!exists ('g:mnemosyne_register_list'))  | let g:mnemosyne_register_list  = 'abcdefghij'        | endif
if (!exists ('g:mnemosyne_modal_window'))   | let g:mnemosyne_modal_window   = 0                   | endif
if (!exists ('g:mnemosyne_split_vertical')) | let g:mnemosyne_split_vertical = 1                   | endif
if (!exists ('g:mnemosyne_window_size'))    | let g:mnemosyne_window_size    = 20                  | endif
if (!exists ('g:mnemosyne_focus_window'))   | let g:mnemosyne_focus_window   = 0                   | endif

" if (!exists ('g:mnemosyne_show_help'))      | let g:mnemosyne_show_help      = 1                   | endif

let s:window_name = '__mnemosyne__'

let s:record_replace = 'REC'
let s:record_append  = 'APP'

let s:file_header = [
	\ '" Mnemosyne.vim - Mistress of Macros',
	\ '" https://github.com/flatcap/vim-mnemosyne'
\ ]

let s:window_comments = [
	\ '" Mnemosyne - https://github.com/flatcap/vim-mnemosyne',
	\ '" Named registers',
	\ '" Unnamed registers',
	\ '" Will be lost when vim is closed',
\ ]

let s:highlight_normal = 'mnemosyne_normal'
let s:highlight_locked = 'mnemosyne_locked'

let s:mnemosyne_recording = ''
let s:mnemosyne_registers = []

function! s:place_sign(buffer, line, char, locked)
	call setpos ("'" . a:char, [a:buffer, a:line, 1, 0])

	if (a:locked)
		let highlight = s:highlight_locked
	else
		let highlight = s:highlight_normal
	endif

	if (a:char == '-')
		let name = 'mnemosyne_dash' . a:locked
	elseif (a:char == '!')
		let name = 'mnemosyne_bang'
	else
		let name = 'mnemosyne_' . a:char
	endif
	execute 'sign define ' . name . ' text=' . a:char . ' texthl=' . highlight
	execute 'sign place ' . a:line . ' name=' . name . ' line=' . a:line . ' buffer=' . a:buffer
endfunction

function! s:generate_window_text()
	let count_var = len (s:mnemosyne_registers)
	let count_reg = len (g:mnemosyne_register_list)
	let count_max = g:mnemosyne_max_macros

	let reg_index = 0
	let rows = []

	let rows += [ { 'data': s:window_comments[0] } ]

	for i in range(count_var)
		if (reg_index < count_reg)
			let letter = g:mnemosyne_register_list[reg_index]
		elseif (reg_index < count_max)
			let letter = '-'
		else
			let letter = '!'
		endif

		if (reg_index == count_reg)
			let rows += [ { 'data': ''                   } ]
			let rows += [ { 'data': s:window_comments[2] } ]
		endif
		if (reg_index == count_max)
			let rows += [ { 'data': ''                   } ]
			let rows += [ { 'data': s:window_comments[3] } ]
		endif

		let reg_index += 1
		if (reg_index == 1)
			let rows += [ { 'data': ''                   } ]
			let rows += [ { 'data': s:window_comments[1] } ]
		endif

		let locked = exists ('s:mnemosyne_registers[i].locked')
		let text = s:mnemosyne_registers[i].data
		if (exists ('s:mnemosyne_registers[i].recording'))
			let text = '[' . s:mnemosyne_registers[i].recording . '] ' . text
		endif

		if (locked)
			let rows += [ { 'letter': letter, 'locked': locked, 'data': text } ]
		else
			let rows += [ { 'letter': letter, 'data': text } ]
		endif
	endfor

	return rows
endfunction

function! s:populate_macro_window()
	let buf_num = bufnr('%')
	execute 'sign unplace * buffer=' . buf_num
	execute 'delmarks!'

	let rows = s:generate_window_text()
	let row_count = len (rows)

	let old_mod = &l:modifiable
	setlocal modifiable

	let win_rows = line('$')
	if (win_rows > row_count)
		execute row_count . ',$d'
	endif

	for i in range(row_count)
		let r = rows[i]

		let old = getline (i+1)
		if ((old != r.data) || (r.data == ''))
			call setline (i+1, r.data)
		endif

		let locked = (exists ('r.locked'))
		let letter = (exists ('r.letter')) ? r.letter : ''

		if (len (letter) > 0)
			call s:place_sign (buf_num, i+1, letter, locked)
		endif
	endfor

	let &l:modifiable = old_mod
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

function! s:is_file_comment (str)
	for c in s:file_header
		if (a:str == c)
			return 1
		endif
	endfor

	return 0
endfunction

function! s:is_window_comment (str)
	for c in s:window_comments
		if (a:str == c)
			return 1
		endif
	endfor

	return 0
endfunction

function! s:parse_header(list)
	let locked = []
	" Scan at more the first 4 lines
	let end = min ([4, len(a:list)-1])

	for i in range(end, 1, -1)
		let line = a:list[i]
		if (s:is_file_comment(line))
			unlet a:list[i]
		endif

		if (line =~? '^" Locked: ')
			let line = substitute (line, '^" Locked: *', '', '')
			let locked = split (line, ',')
			unlet a:list[i]
		endif

	endfor
	return locked
endfunction

function! s:get_index (line_num)
	let index = -1
	for i in range (1, a:line_num)
		let line = getline(i)
		if (line =~ '^\s*$')
			"XXX false positive on 'dull' macros
			continue
		endif
		if (s:is_window_comment (line))
			continue
		endif
		let index += 1
	endfor
	echo line
	if ((line =~ '^\s*$') || (s:is_window_comment (line)))
		return -1
	endif
	return index
endfunction

function! s:sync_registers_to_var()
	let count_var = len(s:mnemosyne_registers)
	let count_reg = len (g:mnemosyne_register_list)

	if (count_var < count_reg)
		" Our variable's empty, create some dummy entries
		for i in range (count_reg - count_var)
			let s:mnemosyne_registers += [ { 'data': '' } ]
		endfor
	endif

	for i in range (count_reg)
		let reg = nr2char (char2nr('a')+i)
		if (exists ('s:mnemosyne_registers[i].locked'))
			" If the var is locked make sure the register matches
			call setreg (reg, s:mnemosyne_registers[i].data)
		else
			" Copy the register into the var
			let s:mnemosyne_registers[i].data = getreg (reg)
		endif
	endfor
endfunction

function! s:sync_var_to_registers()
	let count_max = min ([len (g:mnemosyne_register_list), len(s:mnemosyne_registers)])
	for i in range (count_max)
		let reg = nr2char (char2nr('a')+i)
		let data = s:mnemosyne_registers[i].data
		call setreg (reg, data)
	endfor
endfunction

function! s:move_registers(...)
	let start = (a:0 > 0) ? a:1 : 0

	call s:sync_registers_to_var()

	call insert (s:mnemosyne_registers, { 'data': '' }, start)

	let num = len(s:mnemosyne_registers) - 1
	for i in range(start, num)
		let reg = s:mnemosyne_registers[i]
		if (exists ('reg.locked'))
			let tmp = s:mnemosyne_registers[i-1]
			let s:mnemosyne_registers[i-1] = s:mnemosyne_registers[i]
			let s:mnemosyne_registers[i] = tmp
		endif
	endfor

	call s:sync_var_to_registers()
endfunction

function! s:var_set_locked (index, value)
	" value: -1 toggle, 0 unlocked, 1 locked

	let count_var = len (s:mnemosyne_registers)
	if ((a:index < 0) || (a:index >= count_var))
		return -1
	endif

	if (value == -1)
		" Toggle the locked value
		let value = !exists ('s:mnemosyne_registers[index].locked')
	endif

	if (value == 1)
		let s:mnemosyne_registers[index].locked = 1
		let locked = 1
	elseif (value == 0)
		unlet! s:mnemosyne_registers[index].locked
		let locked = 0
	else
		return -1
	endif

	return locked
endfunction

function! s:repopulate()
	let win_macro = s:find_window_number()
	if (win_macro < 0)
		return
	endif

	" Save the user's current location
	let cur_user = getpos('.')
	let win_user = winnr()

	call s:sync_registers_to_var()

	execute win_macro . 'wincmd w'
	call s:populate_macro_window()

	execute win_user . 'wincmd w'
	call setpos ('.', cur_user)
endfunction


function! s:create_window(modal, vertical)
	if (a:modal)
		" Modal Window
		execute 'silent enew'
		execute 'silent file ' . s:window_name
	else
		" Split Window
		let vert = (a:vertical) ? 'vertical' : ''
		execute 'silent ' . vert . ' new'
		execute 'silent file ' . s:window_name
	endif

	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal nobuflisted
	setlocal noswapfile
	setlocal filetype=vim

	nnoremap <buffer> <silent> q :<c-u>call CloseWindow()<cr>
	nnoremap <buffer> <silent> \p :<c-u>call WindowToggleLocked()<cr>
	nnoremap <buffer> <silent> `- /^" Unnamed/+1<cr>
	nnoremap <buffer> <silent> `! /^" Will/+1<cr>

	augroup MacroWindow
		autocmd!
		autocmd BufWinLeave <buffer> let b:cursor = getpos ('.')
	augroup END

	execute 'syntax match m_recording "^\[' . s:record_replace . '\]"'
	execute 'syntax match m_recording "^\[' . s:record_append  . '\]"'
	highlight m_recording ctermfg=red
endfunction


function! WindowToggleLocked()
	let line_num = getpos('.')[1]
	let index = s:get_index (line_num)
	if (index < 0)
		return
	endif

	let locked = s:var_set_locked (index, -1)

	if (locked != -1)
		call s:repopulate()
	endif
endfunction

function! ReadMacrosFromFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let file = expand (file)

	if (!filereadable (file))
		return
	endif

	let list = readfile (file)

	let s:mnemosyne_registers = []

	let locked = s:parse_header (list)

	let reg_index = 0
	for line in list
		if ((line =~ '^\s*$') || (line =~ '^\s*".*$'))
			continue
		endif

		let reg_index += 1
		let entry = { 'data' : line }

		if (index (locked, ''.reg_index) >= 0)
			let entry.locked = 1
		endif

		call add (s:mnemosyne_registers, entry)
	endfor
	call s:sync_var_to_registers()
	call s:repopulate()
endfunction

function! SaveMacrosToFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let file = expand (file)

	let dir = fnamemodify (file, ':h')
	if (!isdirectory (dir))
		return
	endif
	if (!filewritable (dir))
		return
	endif

	call s:sync_registers_to_var()

	let list = copy (s:file_header)

	let count_var = len(s:mnemosyne_registers)
	let count_reg = len (g:mnemosyne_register_list)
	let count_max = min ([count_var, g:mnemosyne_max_macros])

	let locked = []
	for i in range(count_max)
		let reg = s:mnemosyne_registers[i]
		let list += [ reg.data ]
		if (exists ('reg.locked'))
			let locked += [ i+1 ]
		endif
	endfor

	if (len (locked) > 0)
		let line = '" Locked: ' . join (locked, ',')
		call insert (list, line, 2)
	endif

	call writefile (list, file)
endfunction


function! OpenWindow(...)
	let opt_modal = (a:0 > 0) ? a:1 : g:mnemosyne_modal_window
	let opt_vert  = (a:0 > 1) ? a:2 : g:mnemosyne_split_vertical
	let opt_size  = (a:0 > 2) ? a:3 : g:mnemosyne_window_size
	let opt_focus = (a:0 > 3) ? a:4 : g:mnemosyne_focus_window

	call s:sync_registers_to_var()

	let win_macro = s:find_window_number()
	if (win_macro >= 0)
		if (opt_focus)
			execute win_macro . 'wincmd w'
		endif
		return
	endif

	" Save the user's current location
	let buf_user = bufnr ('%')
	let cur_user = getpos('.')
	let win_user = winnr()

	let mod_buf = bufnr (s:window_name)

	if (mod_buf < 0)
		call s:create_window (opt_modal, opt_vert)
	else
		" Recycle existing buffer
		if (opt_modal)
			" Modal Window
			execute 'silent ' . mod_buf . 'buffer'
		else
			" Split Window
			let vertical = (opt_vert) ? 'vertical' : ''
			execute 'silent ' . vertical . ' split'
			execute 'silent ' . mod_buf . 'buffer'
		endif
	endif

	if (opt_modal)
		" Modal Window
		let w:return_buffer = buf_user
		let w:return_cursor = cur_user
	else
		" Split Window
		let vertical = (opt_vert) ? 'vertical' : ''

		if (opt_size > 0)
			if (opt_vert)
				execute opt_size . ' wincmd |'
			else
				execute opt_size . ' wincmd _'
			endif
		endif

		unlet! w:return_buffer
		unlet! w:return_cursor
	endif

	call s:populate_macro_window()

	if (exists ('b:cursor'))
		call setpos ('.', b:cursor)
	else
		normal 3Gzt
	endif

	if (!opt_focus)
		" Restore the user's focus
		execute win_user . 'wincmd w'
		call setpos ('.', cur_user)
	endif
endfunction

function! CloseWindow()
	let win_macro = s:find_window_number()
	if (win_macro < 0)
		return
	endif

	"XXX sync window to var
	"XXX sync var to reg

	let cur_user = getpos('.')
	let win_user = winnr()

	if (win_macro != win_user)
		execute win_macro . 'wincmd w'
	endif

	" We're now IN the Macro Window

	if (exists ('w:return_buffer') && exists ('w:return_cursor'))
		" Modal Window
		execute w:return_buffer . 'buffer'
		call setpos ('.', w:return_cursor)
	else
		" Split Window
		quit!
	endif

	if (win_macro != win_user)
		execute win_user . 'wincmd w'
		call setpos ('.', cur_user)
	endif
endfunction

function! ToggleWindow()
	let win_macro = s:find_window_number()
	if (win_macro >= 0)
		call CloseWindow()
	else
		call OpenWindow()
	endif
endfunction

function! ShowRegisters(...)
	let show_all = (a:0 > 0) ? a:1 : 0

	call s:sync_registers_to_var()

	let count_var = len(s:mnemosyne_registers)
	let count_reg = len(g:mnemosyne_register_list)

	if (!count_var)
		return
	endif

	echohl MoreMsg
	if (show_all)
		let count_display = count_var
		echo 'Mnemosyne: ' . count_display . ' registers (locked*)'
	else
		let count_display = count_reg
		echo 'Mnemosyne: ' . count_display . ' named registers (locked*)'
	endif
	echohl None

	for i in range(count_display)
		if (i < count_reg)
			let letter = g:mnemosyne_register_list[i]
		elseif (i < g:mnemosyne_max_macros)
			let letter = '-'
		else
			let letter = '!'
		endif
		let contents = s:mnemosyne_registers[i].data
		let contents = substitute (contents, nr2char(9), '^I', 'g')
		let contents = substitute (contents, nr2char(10), '^J', 'g')
		let contents = substitute (contents, nr2char(13), '^M', 'g')
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let flags = (exists ('s:mnemosyne_registers[i].locked')) ? '*' : ' '
		echo printf ('  %s%s : %s', letter, flags, contents)
	endfor
endfunction

function! InterceptQ()
	" q no timeout waiting for register name
	" q{0-9a-zA-Z"}
	" q: q/ q?
	if (s:mnemosyne_recording != '')
		let reg = tolower (s:mnemosyne_recording)
		let s:mnemosyne_recording = ''
		let index = stridx (g:mnemosyne_register_list, tolower(reg))
		unlet! s:mnemosyne_registers[index].recording

		normal! q
		let val = substitute (getreg(reg), '\=q$', '', '')
		call setreg (reg, val)
		call s:sync_registers_to_var()
		call s:repopulate()
		return
	endif

	let c = getchar()
	if ((type(c) == type('')) || (c >= 128))
		return
	endif

	let c = nr2char(c)
	if (c =~ '^[:/?]$')
		" Delegate without tracking
		call feedkeys ('q' . c, 'n')
		return
	endif

	let index = stridx (g:mnemosyne_register_list, tolower(c))
	if (index < 0)
		if (c =~ '[0-9a-zA-Z"]')
			" Delegate and track
			let s:mnemosyne_recording = c
			execute 'normal! q' . c
		endif
		return
	endif

	let item = s:mnemosyne_registers[index]
	if (exists ('item.locked'))
		echohl error
		echom 'Mnemosyne: Register ' . c . ' is locked'
		echohl none
		return
	endif

	" Intercept and track
	if (c =~# '[a-z]')
		call s:move_registers(index)
	endif
	let s:mnemosyne_recording = c
	execute 'normal! q' . c

	if (c =~# '[A-Z]')
		echom 'APPEND'
		let s:mnemosyne_registers[index].recording = s:record_append
	else
		echom 'REPLACE'
		let s:mnemosyne_registers[index].recording = s:record_replace
	endif
	call s:repopulate()
endfunction


function! ClearRegisters()
	for i in range (10)
		call setreg (i, '')
	endfor
	for i in range (26)
		let reg = nr2char (char2nr ('a')+i)
		call setreg (reg, '')
	endfor
	call s:sync_registers_to_var()
	call s:repopulate()
endfunction

function! LastEdit()
	let undo = undotree()
	return undo.time_cur
endfunction

function! MaintainList()
	let cursor = getpos ('.')
	call s:strip_out_system_comments()
	call s:insert_system_comments()
	call s:populate_window()
	call setpos ('.', cursor)
endfunction


call ReadMacrosFromFile()

nnoremap <silent> q :<c-u>call InterceptQ()<cr>

nnoremap <silent> <leader>ml :<c-u>call ShowRegisters(1)<cr>
nnoremap <silent> <leader>mn :<c-u>call WindowToggleLocked()<cr>
nnoremap <silent> <leader>mr :<c-u>call ReadMacrosFromFile()<cr>
nnoremap <silent> <leader>ms :<c-u>call SaveMacrosToFile()<cr>
nnoremap <silent> <leader>mt :<c-u>call ToggleWindow()<cr>
nnoremap <silent> <leader>mx :<c-u>call ClearRegisters()<cr>

nnoremap <silent> [29~ :<c-u>call ToggleWindow()<cr>
nnoremap <silent> <F12> :update<cr>:source plugin/mnemosyne.vim<cr>

highlight mnemosyne_normal   ctermbg=17 ctermfg=white
highlight mnemosyne_locked   ctermbg=17 ctermfg=white cterm=reverse
highlight SignColumn         ctermbg=17

augroup MacroGlobal
	autocmd!
	autocmd VimLeavePre * call SaveMacrosToFile()
augroup END

" augroup MaintainList
" 	autocmd!
" 	autocmd CursorMoved <buffer=2> call MaintainList()
" augroup END

