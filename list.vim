let s:reg_list = 'abcdefghij'
let s:max_reg  = 15

function! g:MaintainList()
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


vsplit config.vim

augroup MaintainList
	autocmd!
	autocmd CursorMoved <buffer=2> call MaintainList()
augroup END


