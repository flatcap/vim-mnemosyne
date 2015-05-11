
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

function! s:populate_window()
	execute '%d'
	call setline (1, '" Modal Window')
	for i in range(1, 20)
		let char = nr2char (char2nr('a')+i-1)
		let msg = char . ' This is entry ' . i
		execute 'normal! o' . msg
	endfor
	execute '2,$!shuf'
endfunction


function! g:OpenModal() abort
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

	setlocal modifiable

	call s:populate_window()

	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal nobuflisted
	setlocal noswapfile
	setlocal nomodifiable
	setlocal cursorline

	mapclear <buffer>

	map <silent> <buffer> q :<c-u>call CloseModal()<cr>
endfunction

function! g:CloseModal()
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

function! g:ToggleModal()
	let winnum = s:find_window_number()
	if (winnum >= 0)
		call CloseModal()
	else
		call OpenModal()
	endif
endfunction


map <silent> <F11> :<c-u>update<bar>source modal.vim<cr>
map <silent> <F12> :<c-u>call ToggleModal()<cr>

