let s:reg_list = 'abcdefghij'
let s:max_reg  = 15
let s:sequence = 0

let s:messages = [
	\ '" Mnemosyne - https://github.com/flatcap/vim-mnemosyne',
	\ '" Named registers',
	\ '" Unnamed registers',
	\ '" Will be lost when vim is closed',
\ ]

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

augroup MaintainList
	autocmd!
	autocmd CursorMoved <buffer=2> call MaintainList()
augroup END

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

