" Mnemosyne

function! SetRegisters()
	let @a = 'apple'
	let @b = 'banana'
	let @c = 'cherry'
	let @d = 'damson'
	let @e = 'elderberry'
	" let @f = 'fig'
	" let @g = 'guava'
	" let @h = 'hawthorn'
	" let @i = 'ilama'
	" let @j = 'jackfruit'
	" let @k = 'kumquat'
	" let @l = 'lemon'
	" let @m = 'mango'
	" let @n = 'nectarine'
	" let @o = 'olive'
	" let @p = 'papaya'
	" let @q = 'quince'
	" let @r = 'raspberry'
	" let @s = 'strawberry'
	" let @t = 'tangerine'
	" let @u = 'ugli'
	" let @v = 'vanilla'
	" let @w = 'wolfberry'
	" let @x = 'xigua'
	" let @y = 'yew'
	" let @z = 'ziziphus'
endfunction

function! MoveRegisters()
	" let @z = @y
	" let @y = @x
	" let @x = @w
	" let @w = @v
	" let @v = @u
	" let @u = @t
	" let @t = @s
	" let @s = @r
	" let @r = @q
	" let @q = @p
	" let @p = @o
	" let @o = @n
	" let @n = @m
	" let @m = @l
	" let @l = @k
	" let @k = @j
	" let @j = @i
	" let @i = @h
	" let @h = @g
	" let @g = @f
	let @f = @e
	let @e = @d
	let @d = @c
	let @c = @b
	let @b = @a
endfunction


nnoremap qa :call MoveRegisters()<cr>qa

