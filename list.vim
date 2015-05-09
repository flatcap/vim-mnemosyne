function! DoStuff()
	let registers = 'abcdefghij'
	let reg_max = len (registers) - 1
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
			let char = registers[reg_idx]
		elseif (reg_idx <= 15)
			let char = '-'
		else
			let char = '"!'
		endif
		let reg_idx += 1

		" call setline(i, char . line)
		echom printf ('%s : %s', char, line)
		" echom '" line ' . i
	endfor
endfunction

" autocmd CursorMoved          * call <SID>DoStuff()

nmap <F12> b:so %<cr>t:call DoStuff()<cr>

