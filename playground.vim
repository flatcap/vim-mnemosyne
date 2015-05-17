
let s:window_name = '__playground__'
let s:help_visible = 0

function! DeleteLine()
	setlocal modifiable
	execute '.,.g/^[^"]/d'
	setlocal nomodifiable
endfunction

function! ToggleHelp()
	setlocal modifiable
	if (s:help_visible)
		execute '2,4g/^"/d'
	else
		normal! gg
		normal! o" help1
		normal! o" help2
		normal! o" help3
	endif
	let s:help_visible = 1 - s:help_visible
	setlocal nomodifiable
endfunction

function! MoveLineDown()
	setlocal modifiable
	normal! ddp
	setlocal nomodifiable
endfunction

function! MoveLineUp()
	setlocal modifiable
	normal! ddkP
	setlocal nomodifiable
endfunction

function! Redo()
	setlocal modifiable
	normal! 
	setlocal nomodifiable
endfunction

function! TogglePin()
	setlocal modifiable
	let line = getline ('.')
	if (line =~ '^\i\*	')
		let line = substitute (line, '\*', '', '')
	else
		let line = substitute (line, '\t', '*\t', '')
	endif
	call setline ('.', line)
	setlocal nomodifiable
endfunction

function! Undo()
	setlocal modifiable
	normal! u
	setlocal nomodifiable
endfunction


function! Playground()
	let bufnum = bufnr (s:window_name)
	if (bufnum >= 0)
		execute 'silent bwipeout ' . bufnum
	endif

	execute 'vertical new ' . s:window_name

	call setline (1, '" Mnemosyne - <F1> for help')
	for i in range (20)
		let char = nr2char (char2nr ('a')+i)
		let msg = char . '	This is line ' . i
		execute 'normal! o' . msg
	endfor
	normal MVUAxxxxxxxxxxxxxxxxxxxxxxxxxx

	mapclear <buffer>

	map <silent> <buffer> q     :<c-u>quit<cr>
	map <silent> <buffer> <c-j> :<c-u>call MoveLineDown()<cr>
	map <silent> <buffer> <c-k> :<c-u>call MoveLineUp()<cr>
	map <silent> <buffer> <c-r> :<c-u>call Redo()<cr>
	map <silent> <buffer> p     :<c-u>call TogglePin()<cr>
	map <silent> <buffer> dd    :<c-u>call DeleteLine()<cr>
	map <silent> <buffer> u     :<c-u>call Undo()<cr>
	map <silent> <buffer> <f1>  :<c-u>call ToggleHelp()<cr>

	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nomodifiable
	setlocal cursorline
endfunction


map <silent> <F12> :<c-u>update<bar>source playground.vim<bar>call Playground()<cr>

