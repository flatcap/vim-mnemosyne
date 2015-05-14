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
if (!exists ('g:mnemosyne_window_size'))    | let g:mnemosyne_window_size    = 30                  | endif

" if (!exists ('g:mnemosyne_magic_map_char')) | let g:mnemosyne_magic_map_char = 'a'                 | endif
" if (!exists ('g:mnemosyne_show_help'))      | let g:mnemosyne_show_help      = 1                   | endif

let s:window_name = '__mnemosyne__'

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

function! s:create_mappings()
	nnoremap <buffer> <silent> q :call CloseWindow()<cr>
	nnoremap <buffer> <silent> \p :call WindowToggleLocked()<cr>
	nnoremap <buffer> <silent> `- /^" Unnamed/+1<cr>
	nnoremap <buffer> <silent> `! /^" Will/+1<cr>

	augroup MacroWindow
		autocmd!
		autocmd BufWinLeave <buffer> let b:cursor = getpos ('.')
	augroup END
endfunction

function! s:populate_macro_window()
	let old_paste = &paste
	setlocal paste
	execute '%d'

	let named   = len (g:mnemosyne_register_list)
	let unnamed = g:mnemosyne_max_macros

	let num = len (s:mnemosyne_registers)
	let comment1 = -1
	let comment2 = -1

	let buf_num = bufnr('%')
	execute 'sign unplace * buffer=' . buf_num
	execute 'delmarks!'

	let reg_count = 0
	for i in range(num)
		if (reg_count < named)
			let letter = g:mnemosyne_register_list[reg_count]
		elseif (reg_count < unnamed)
			let letter = '-'
		else
			let letter = '!'
		endif

		if (reg_count == named)
			let comment1 = i
		endif
		if (reg_count == unnamed)
			let comment2 = i
		endif
		let reg_count += 1

		let locked = exists ('s:mnemosyne_registers[i].locked')
		let line = line('$')
		let text = s:mnemosyne_registers[i].data
		call append (line-1, text)

		call s:place_sign (buf_num, line, letter, locked)
	endfor

	if (comment2 >= 0)
		call append (comment2, s:window_comments[3])
		call append (comment2, '')
	endif
	if (comment1 >= 0)
		call append (comment1, s:window_comments[2])
		call append (comment1, '')
	endif
	if (reg_count > 0)
		call append (0, s:window_comments[1])
	endif
	call append (0, '')
	call append (0, s:window_comments[0])

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

function! WindowToggleLocked()
	let line_num = getpos('.')[1]
	let index = s:get_index (line_num)
	if (index < 0)
		return
	endif

	if (exists ('s:mnemosyne_registers[index].locked'))
		unlet s:mnemosyne_registers[index].locked
		let locked = 0
	else
		let s:mnemosyne_registers[index].locked = 1
		let locked = 1
	endif

	let buf_num = bufnr('%')

	let named   = len (g:mnemosyne_register_list)
	let unnamed = g:mnemosyne_max_macros

	if (index < named)
		let letter = g:mnemosyne_register_list[index]
	elseif (index < unnamed)
		let letter = '-'
	else
		let letter = '!'
	endif

	if (letter != '!')
		call s:place_sign (buf_num, line_num, letter, locked)
	endif

	call SyncVarToRegisters()
endfunction


function! SyncRegistersToVar()
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
		let s:mnemosyne_registers[i].data = getreg (reg)
	endfor
endfunction

function! MoveRegisters()
	call SyncRegistersToVar()

	call insert (s:mnemosyne_registers, { 'data': '' }, 0)

	let num = len(s:mnemosyne_registers)
	for i in range(num)
		let reg = s:mnemosyne_registers[i]
		if (exists ('reg.locked'))
			let tmp = s:mnemosyne_registers[i-1]
			let s:mnemosyne_registers[i-1] = s:mnemosyne_registers[i]
			let s:mnemosyne_registers[i] = tmp
		endif
	endfor

	call SyncVarToRegisters()
	call ShowRegisters(1)
endfunction

function! SyncVarToRegisters()
	let count_max = min ([len (g:mnemosyne_register_list), len(s:mnemosyne_registers)])
	for i in range (count_max)
		let reg = nr2char (char2nr('a')+i)
		let data = s:mnemosyne_registers[i].data
		call setreg (reg, data)
	endfor
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
	call SyncVarToRegisters()
endfunction

function! SaveMacrosToFile (...)
	let file = (a:0 > 0) ? a:1 : g:mnemosyne_macro_file
	let file = expand (file)

	let dir = fnamemodify (file, ':h')
	if (!isdirectory (dir))
		echom 'NO DIR: ' . dir
		return
	endif
	if (!filewritable (dir))
		echom 'NO DIR WRITE: ' . file
		return
	endif

	call SyncRegistersToVar()

	let list = copy (s:file_header)

	let count_var = len(s:mnemosyne_registers)
	let count_reg = len (g:mnemosyne_register_list)
	let count_max = min ([count_var, g:mnemosyne_max_macros])
	echom printf ('%d, %d, %d', count_var, count_reg, count_max)

	echom 'WRITE: ' . count_max . ' ENTRIES'
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

	call SyncRegistersToVar()

	let winnum = s:find_window_number()
	if (winnum >= 0)
		execute winnum . 'wincmd w'
		return
	endif

	let bufnum = bufnr ('%')
	let cursor = getpos ('.')

	let mod_buf = bufnr (s:window_name)

	if (opt_modal)
		" Modal Window
		if (mod_buf < 0)
			" Create new buffer
			execute 'silent enew'
			execute 'silent file ' . s:window_name
			call s:create_mappings()
		else
			" Recycle existing buffer
			execute 'silent ' . mod_buf . 'buffer'
		endif

		let w:return_buffer = bufnum
		let w:return_cursor = cursor
	else
		" Split Window
		let vertical = (opt_vert) ? 'vertical' : ''
		if (mod_buf < 0)
			" Create new buffer
			execute 'silent ' . vertical . ' new'
			execute 'silent file ' . s:window_name
			call s:create_mappings()
		else
			" Recycle existing buffer
			execute 'silent ' . vertical . ' split'
			execute 'silent ' . mod_buf . 'buffer'
		endif

		unlet! w:return_buffer
		unlet! w:return_cursor
	endif

	if (!opt_modal && (opt_size > 0))
		if (opt_vert)
			execute opt_size . ' wincmd |'
		else
			execute opt_size . ' wincmd _'
		endif
	endif

	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal nobuflisted
	setlocal noswapfile
	setlocal filetype=vim
	" setlocal cursorline

	setlocal modifiable
	call s:populate_macro_window()
	setlocal nomodifiable

	if (exists ('b:cursor'))
		call setpos ('.', b:cursor)
	else
		normal 1G
	endif
endfunction

function! CloseWindow()
	let win_macro = s:find_window_number()
	if (win_macro < 0)
		return
	endif

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

	call SyncRegistersToVar()

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
		let contents = substitute (contents, nr2char(10), '^J', 'g')
		let contents = substitute (contents, nr2char(13), '^M', 'g')
		let contents = substitute (contents, ' ', '␣', 'g')
		let contents = substitute (contents, '\%' . (&columns - 20) . 'v.*', ' ⋯', '')
		let flags = (exists ('s:mnemosyne_registers[i].locked')) ? '*' : ' '
		echo printf ('  %s%s : %s', letter, flags, contents)
	endfor
endfunction

function! ClearRegisters()
	for i in range (10)
		call setreg (i, '')
	endfor
	for i in range (26)
		let reg = nr2char (char2nr ('a')+i)
		call setreg (reg, '')
	endfor
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


" augroup MaintainList
" 	autocmd!
" 	autocmd CursorMoved <buffer=2> call MaintainList()
" augroup END

" nnoremap <silent> <F11> :<c-u>call MaintainList()<cr>
" nnoremap <silent> <F12> :wincmd t<bar>only<bar>update<bar>source %<cr>

" q no timeout waiting for register name
" q{0-9a-zA-Z"}
" q: q/ q?
" <esc>, <space>, <enter> cancels

function! InterceptQ()
	if (s:mnemosyne_recording != '')
		let reg = tolower (s:mnemosyne_recording)
		let s:mnemosyne_recording = ''

		normal! q
		let val = substitute (getreg(reg), '\=q$', '', '')
		call setreg (reg, val)
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

	if (stridx (g:mnemosyne_register_list, c) < 0)
		if (c =~ '[0-9a-zA-Z"]')
			" Delegate and track
			let s:mnemosyne_recording = c
			execute 'normal! q' . c
		endif
		return
	endif

	" Intercept and track
	call MoveRegisters()
	let s:mnemosyne_recording = c
	execute 'normal! q' . c
endfunction


nnoremap <silent> q :<c-u>call InterceptQ()<cr>

call ReadMacrosFromFile()

nnoremap <silent> <leader>ml :call ShowRegisters(1)<cr>
nnoremap <silent> <leader>mm :call MoveRegisters()<cr>
nnoremap <silent> <leader>mr :wall<bar>source %<bar>call ReadMacrosFromFile()<cr>
nnoremap <silent> <leader>ms :call SaveMacrosToFile()<cr>
nnoremap <silent> <leader>mt :call ToggleWindow()<cr>
nnoremap <silent> <leader>mv :call SyncRegistersToVar()<cr>
nnoremap <silent> <leader>mx :call ClearRegisters()<cr>
nnoremap <silent> <leader>mn :call WindowToggleLocked()<cr>

nnoremap <silent> <F12> :update<cr>:source plugin/mnemosyne.vim<cr>

highlight mnemosyne_normal   ctermfg=red      ctermbg=white
highlight mnemosyne_locked   ctermfg=yellow   ctermbg=blue
highlight SignColumn         ctermbg=magenta

augroup MacroGlobal
	autocmd!
	autocmd VimLeavePre * call SaveMacrosToFile()
augroup END

