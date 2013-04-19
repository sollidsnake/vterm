" Vim shell plugin
" (:)

"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `pwd | awk -F\"/\" '{print $NF}' | sed 's/\\///' `]$  ")
"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `echo ". expand("%:p:h") . " | sed 's/\\///' `]$  ")
let g:VTermExtraSpace = 2
let g:VTermPs1 = "[%U@%H] [%D] $"

" Format ps1 variable
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

" The cd command executed in the shell won't take effect inside vim.  So in
" order to update the current dir shown in the term buffer we need to the
" entered command is a cd to execute it inside vim.
function vterm#Cd( cmd )
  let l:c = 0
  " The loop will check the cmd variable for the first non-empty space, when
  " found, check if it's an cd command, then execute the cd command inside vim
  " to update the directory. 
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

" execute the entered command
function vterm#Cmd()
  " separate the command from the ps1
  let l:cmd = strpart(getline('.'), (g:VTermPs1Len ) , strlen(getline('.')))

  let l:out = system(l:cmd)
  
  " print output on screen
  put = l:out

  " check for cd command
  call vterm#Cd(l:cmd)
  "call feedkeys(" A\<Enter>\<Esc>", "n")
  " add line in the end of buffer
  "$s/$/\r/
  call vterm#PutPs1()
endfunction

" print ps1 in the screen
function vterm#PutPs1()
  " get the formated ps1 string
  let g:VTermPs1Lit = vterm#SetPs1(g:VTermPs1)
  " check the length for parsing the command
  let g:VTermPs1Len = strlen(g:VTermPs1Lit)

  " check for extra spaces and ignore them in the count for the entered command
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
    $join
  endif
  call cursor(line('.'), g:VTermPs1Len + g:VTermExtraSpace)
endfunction

" clear the screen
function vterm#Clear()
  %s/.*//g|%s/\n//g
  call vterm#PutPs1()
endfunction

" start the term
function vterm#Start()
  " shell
  e /tmp/vim-shell.txt
  call vterm#PutPs1()
  
  " local mapping
  inoremap <buffer><Enter> <Esc>:call vterm#Cmd()<cr>
  nnoremap <buffer><Enter> <Esc>:call Vterm#Cmd()<cr>
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
