let s:reg_list = 'abcdefghij'
let s:max_reg  = 15
let s:sequence = 0
let s:window_name = '__playground__'
let s:registers = []

let s:messages = [
	\ '" Mnemosyne - https://github.com/flatcap/vim-mnemosyne',
	\ '" Named registers',
	\ '" Unnamed registers',
	\ '" Will be lost when vim is closed',
\ ]

function! s:num_compare (i1, i2)
	return a:i1 - a:i2
endfunction

function! s:dump_registers()
	for i in s:registers
		let locked = (exists ('i.locked')) ? '*' : ''
		if (exists ('i.letter'))
			let letter = i.letter
		else
			let letter = '-'
		endif
		let data  = i.data
		if (exists ('i.comment'))
			if ((len (data > 2)) && (data[2] ==# 'u'))
				echohl green
			else
				echohl red
			endif
			echom printf ("%s ", data)
		else
			if (letter =~? '[a-z]')
				echohl yellow
			elseif (letter == '-')
				echohl cyan
			else
				echohl magenta
			endif
			echo printf ("%s%s\t%s", letter, locked, data)
		endif
		echohl none
	endfor
endfunction


function! s:create_window_read_config()
	execute 'vnew ' . s:window_name

	mapclear <buffer>
	nnoremap <buffer> <silent> q :quit!<cr>

	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal nobuflisted
	setlocal noswapfile
	setlocal cursorline
	setlocal filetype=vim

	execute '0r config.vim'
	normal 3G
	execute '50wincmd <'
	" wincmd t
endfunction

function! s:strip_out_system_comments()
	let num = line('$')

	let s:registers = []

	for i in range (1, num+1)
		let line = getline(i)
		if (line =~ '^\s*$')
			continue
		endif

		let ignore = 0
		for m in s:messages
			if (line == m)
				let ignore = 1
				break
			endif
		endfor
		if (ignore)
			continue
		endif

		let letter = line[0]
		let locked = (line[1] == '*')

		let line = substitute (line, '^.\**\t', '', '')

		let entry = { 'letter': letter, 'data': line }
		if (line[0] == '"')
			let entry.comment = 1
		endif
		if (locked)
			let entry.locked = 1
		endif
		call add (s:registers, entry)
	endfor

	" call s:dump_registers()
endfunction

function! s:insert_system_comments()
	let named   = len (s:reg_list)
	let unnamed = s:max_reg

	let num = len (s:registers)
	let comment1 = 0
	let comment2 = 0

	let reg_count = 0
	for i in range(num)
		if (exists ('s:registers[i].comment'))
			continue
		endif
		if (reg_count < named)
			let s:registers[i].letter = s:reg_list[reg_count]
		elseif (reg_count < unnamed)
			let s:registers[i].letter = '-'
		else
			let s:registers[i].letter = '"'
		endif
		if (reg_count == named)
			let comment1 = i
		endif
		if (reg_count == unnamed)
			let comment2 = i
		endif
		let reg_count += 1
	endfor

	call insert (s:registers, { 'comment': 1, 'data': s:messages[3] }, comment2)
	call insert (s:registers, { 'comment': 1, 'data': ''            }, comment2)
	call insert (s:registers, { 'comment': 1, 'data': s:messages[2] }, comment1)
	call insert (s:registers, { 'comment': 1, 'data': ''            }, comment1)
	call insert (s:registers, { 'comment': 1, 'data': s:messages[1] }, 0)
	call insert (s:registers, { 'comment': 1, 'data': s:messages[0] }, 0)
	call insert (s:registers, { 'comment': 1, 'data': ''            }, 1)

endfunction


function! g:LastEdit()
	let undo = undotree()
	return undo.time_cur
endfunction

function! g:StatusLine()
	return strftime('%c',LastEdit()) . ' ' . s:sequence
endfunction

function! g:MaintainList()
	" set title titlestring=%{strftime('%c',LastEdit())}
	" set statusline=%<%f\ %h%m%r\ %y%=%{v:register}\ %-14.(%l,%c%V%)\ %P

	let s:sequence += 1
	set statusline=%{StatusLine()}

	if (!exists ('w:last_update'))
		let w:last_update = 0
	endif

	let edit = LastEdit()
	if (edit == w:last_update)
		return
	endif

	let w:last_update = edit
	return
	let reg_max = len (s:reg_list) - 1
	let reg_idx = 0

	let max_line = line('$') + 1
	for i in range (1, max_line)
		let line = getline(i)

		if (line =~ '^\v\s*".*$')
			" echom line
			" echom '" comment ' . i
			continue
		endif

		if (line =~ '^\s*$')
			" echom ''
			" echom '" empty ' . i
			continue
		endif

		let line = substitute (line, '\v^.(.*)', '\1', '')

		if (reg_idx <= reg_max)
			let char = s:reg_list[reg_idx]
		elseif (reg_idx <= 15)
			let char = '-'
		else
			let char = '"'
		endif
		let reg_idx += 1

		call setline(i, char . line)
		" echom printf ('%s : %s', char, line)
		" echom '" line ' . i
	endfor
endfunction


" vsplit config.vim

" augroup MaintainList
" 	autocmd!
" 	autocmd CursorMoved <buffer=2> call MaintainList()
" augroup END

function! s:parse_config()
	let f = readfile ('config.vim')

	let num = len(f) - 1
	for i in range(num, 0, -1)
		if (f[i] =~ '^\s*$')
			unlet f[i]
			continue
		endif
		for m in s:messages
			if (f[i] == m)
				unlet f[i]
			endif
		endfor
	endfor

	for i in f
		echo i
	endfor
endfunction


call s:create_window_read_config()
call s:strip_out_system_comments()
call s:insert_system_comments()
call s:dump_registers()

map <F12> :wincmd t<bar>only<bar>update<bar>source %<cr>

