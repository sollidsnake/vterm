" Vim shell plugin
" (:)

"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `pwd | awk -F\"/\" '{print $NF}' | sed 's/\\///' `]$  ")
"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `echo ". expand("%:p:h") . " | sed 's/\\///' `]$  ")
let g:VTermExtraSpace = 2
let g:VTermPs1 = "[%U@%H] [%D] $"

function vterm#SetPs1( ps1 )
  let l:ps1 = a:ps1
  
  let l:dir = getcwd()
  let l:dir = strpart(l:dir, strridx(l:dir, "/"), strlen(l:dir))
  let l:dir = substitute(l:dir, "/", "", "")

  let l:ps1 = substitute((substitute(l:ps1, "%U", system("echo $USER"), "")), "\n", "", "")
  let l:ps1 = substitute(l:ps1, "%D", l:dir, "")
  
  let l:ps1 = substitute((substitute(l:ps1, "%H", system("echo $HOSTNAME"), "")), "\n", "", "")

  return l:ps1
endfunction

function vterm#Cd( cmd )
  let l:c = 0
  while l:c < strlen(a:cmd)
    if a:cmd[l:c] != " "
      if strpart(a:cmd, l:c, 2) == "cd"
		if strlen(a:cmd) == l:c + 2 || a:cmd[l:c + 2] == " "
          exec "silent! cd " . strpart(a:cmd, l:c + 2, strlen(a:cmd))
		endif
      endif
      break
    endif
    let l:c += 1
  endwhile
endfunction

function vterm#Cmd()
  let l:cmd = strpart(getline('.'), (g:VTermPs1Len ) , strlen(getline('.')))
  let l:out = system(l:cmd)
  put = l:out
  call vterm#Cd(l:cmd)
  call feedkeys(" A\<Enter>\<Esc>", "n")
  call vterm#PutPs1()
endfunction

function vterm#PutPs1()
  let g:VTermPs1Lit = vterm#SetPs1(g:VTermPs1)
  let g:VTermPs1Len = strlen(g:VTermPs1Lit)

  let l:c = 0
  while l:c < g:VTermExtraSpace
	let g:VTermPs1Lit .= " "
	let l:c += 1
  endwhile

  "call feedkeys("\<Esc>:put = g:VTermPs1Lit\<CR>kJ", "n")
  put = g:VTermPs1Lit
  "call feedkeys("kJ$", "n")
  if line('.') == 2
    1join
  else 
    exec line('$') . "join"
  endif
  call cursor(line('.'), g:VTermPs1Len + g:VTermExtraSpace)
endfunction

function vterm#Clear()
  %s/.*//g|%s/\n//g
  call vterm#PutPs1()
endfunction

function vterm#Start()
  " shell
  e /tmp/vim-shell.txt
  call vterm#PutPs1()
  
  " local mapping
  inoremap <buffer><Enter> <Esc>:call vterm#Cmd()<cr>
  nnoremap <buffer><Enter> <Esc>:call Vtermcmd()<cr>
  inoremap <buffer><c-l> :call Vtermclear()<cr>
  nnoremap <buffer><c-l> :call Vtermclear()<cr>
  
  " go to start remaps
  let l:maps = ["v", "n"]
  for l:m in l:maps
	execute l:m . "noremap <buffer>0 :call VtermgoToStart()<CR>"
	execute l:m . "noremap <buffer>^ :call VtermgoToStart()<CR>"
  endfor
  
endfunction

function vterm#GoToStart()
  let g:VTermPs1Len = strlen(g:VTermPs1Lit)
  call cursor( (g:VTermPs1Len + 1) . "|", "n")
endfunction

command VTermStart call vterm#Start()
