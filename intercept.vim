
" q no timeout waiting for register name
" q{0-9a-zA-Z"}
" q: q/ q?
" <esc>, <space>, <enter> cancels

function! InterceptQ()
	let c = getchar()
	if ((c >= 128) || (type(c) == type('')))
		return
	endif

	echohl error
	echom 'Intercept: q' . nr2char(c)
	echohl none
endfunction

nnoremap <silent> <buffer> q :<c-u>call InterceptQ()<cr>

