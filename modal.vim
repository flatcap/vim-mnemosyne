
let s:window_name = '__modal__'

function! s:find_window_number()
	let win_max = winnr ('$')
	for i in range (1, win_max)
		if (bufname (winbufnr (i)) == s:window_name)
			return i
		endif
	endfor

	return -1
endfunction

function! OpenModal() abort
	let winnum = s:find_window_number()
	if (winnum >= 0)
		execute winnum . 'wincmd w'
		return
	endif

	let bufnum = bufnr ('%')
	let cursor = getpos ('.')

	execute 'silent enew'
	execute 'silent file ' . s:window_name

	let w:return_buffer = bufnum
	let w:return_cursor = cursor

	for i in range(1, 20)
		let char = nr2char (char2nr('a')+i-1)
		let msg = char . ' This is line ' . i
		call setline (i, msg)
	endfor

	mapclear <buffer>

	map <silent> <buffer> q :<c-u>quit<cr>

	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nomodifiable
	setlocal cursorline
endfunction

function! CloseModal()
	let this_win = winnr()

	let winnum = s:find_window_number()
	if (winnum < 0)
		return
	endif

	execute winnum . 'wincmd w'

	if (exists ('w:return_buffer'))
		execute 'silent ' . w:return_buffer . 'buffer'
	endif

	if (exists ('w:return_cursor'))
		call setpos ('.', w:return_cursor)
	endif
endfunction

function! ToggleModal()
	let winnum = s:find_window_number()
	if (winnum >= 0)
		call CloseModal()
	else
		call OpenModal()
	endif
endfunction


map <silent> <F12> :<c-u>update<bar>source modal.vim<bar>call ToggleModal()<cr>

