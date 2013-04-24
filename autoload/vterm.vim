" VTerm
" terminal inside vim

"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `pwd | awk -F\"/\" '{print $NF}' | sed 's/\\///' `]$  ")
"let g:VTermPs1 = system("echo \[$USER\"@\"$HOSTNAME `echo ". expand("%:p:h") . " | sed 's/\\///' `]$  ")

let g:VTermExtraSpace = 2
let g:VTermPs1 = "[%U@%H %D] $"
let s:VTermCount=1
let s:VTermCurCmd=""
let g:VTermHist = []
let g:VTermPersistentInsert=1

let g:VTermKeyPrevHist = "<C-p>"
let g:VTermKeyNextHist = "<C-n>"
let g:VTermKeyClear = "<C-l>"

" start the term
function! vterm#Start()
  " open buffer in tmp dir
  execute "e /tmp/vim-shell" . s:VTermCount . ".vterm"
  let g:VTermCurId = 0
  let s:VTermCount += 1
  
  " do not ask to confirm changes when close the term
  autocmd QuitPre <buffer> silent write | return 0
  autocmd CursorMoved <buffer> call vterm#LimitCursor()
  
  " clear screen in case it's an old buffer
  call vterm#Clear( 0 )
  
  " buff mapping
  inoremap <buffer><Enter> <Esc>:call vterm#Cmd()<cr>
  nnoremap <buffer><Enter> <Esc>:call vterm#Cmd()<cr>
  
  exec "inoremap <silent> <buffer> " . g:VTermKeyPrevHist . " <Esc>:call vterm#GoHist('prev')<CR>i"
  exec "nnoremap <silent> <buffer> " . g:VTermKeyPrevHist . " <Esc>:call vterm#GoHist('prev')<CR>"
  exec "inoremap <silent> <buffer> " . g:VTermKeyNextHist . " <Esc>:call vterm#GoHist('next')<CR>i"
  exec "nnoremap <silent> <buffer> " . g:VTermKeyNextHist . " <Esc>:call vterm#GoHist('next')<CR>"
  exec "inoremap <silent> <buffer> " . g:VTermKeyClear . " <Esc>:call vterm#Clear( 1 )<cr>"
  exec "nnoremap <silent> <buffer> " . g:VTermKeyClear . " <Esc>:call vterm#Clear( 1 )<cr>"
  
  call s:VTermPersistentInsert()
endfunction

" Format ps1 variable
function! vterm#SetPs1( ps1 )
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
function! vterm#Cd( cmd )
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
function! vterm#Cmd()
  if line('$') != line('.')
    call feedkeys("\<Enter>", "n")
    return 0
  endif

  " separate the command from the ps1
  let l:cmd = strpart(getline('.'), (g:VTermPs1Len ) , strlen(getline('.')))
  let l:nospc = substitute(l:cmd, " ", "", "g")
  
  " if l:out is only spaces, clear it
  if l:nospc==""
    let l:out = ""
  else " execute cmd and store it in hist variable
    let l:out = system(l:cmd)
    call add(g:VTermHist, l:cmd)
    let g:VTermCurId = len(g:VTermHist)
    let s:VTermCurCmd = ""
  endif
  
  " print output on screen
  silent put = l:out
  " check for cd command
  call vterm#Cd(l:cmd)
  
  " print ps1 variable on the screen
  call vterm#PutPs1(0)
  
  " the put command will write an extra line on the screen,
  " if the output command, we don't need that extra line,
  " so delete the line before the last
  if empty(l:out)
    exec line('$') - 2 . "join"
  endif
  
  " place the cursor at the end of the last line
  call cursor( line('$'), col('$') )
  
  call s:VTermPersistentInsert()
endfunction

" print ps1 in the screen
function! vterm#PutPs1( cmd )
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

  if !empty(a:cmd) 
    let l:cmd = a:cmd
    " remove initial space characters
    while l:cmd[0]==" "
      let l:cmd = substitute(l:cmd, " ", "", "")
    endwhile
    if empty(l:cmd)
      let l:cmd = " "
    endif
    let g:VTermPs1Lit = strpart(g:VTermPs1Lit, 0, strlen(g:VTermPs1Lit)-1) . l:cmd
  endif
  
  put = g:VTermPs1Lit
  if line('.') == 2
    silent 1join
  else 
    silent $join
  endif
endfunction

function! vterm#LimitCursor()
  " dont let the cursor stay over the current ps1
  if col('.') < g:VTermPs1Len + g:VTermExtraSpace && line('.') == line('$') 
    call vterm#GoToStart()
  endif
  
  " if the cursor is not in the last line, no need to write anything (does it?)
  if line('$') != line('.')
    setlocal nomodifiable
  else
    setlocal modifiable
  endif
endfunction

" clear the screen
function! vterm#Clear( keepCmd )
  " a:keepCmd parameter will decide if the current
  " cmd will be erased or kept
  
  if !empty(a:keepCmd)
    let l:cmd = strpart(getline('.'), (g:VTermPs1Len ) , strlen(getline('.')))
  endif
  
  " delete everything
  silent %s/.*//g|%s/\n//g
  
  " print ps1 on the screen
  if exists("l:cmd")
    call vterm#PutPs1(l:cmd)
  else
    call vterm#PutPs1(0)
  endif
  
  call cursor('.', col('$'))
  call s:VTermPersistentInsert()
endfunction

function! vterm#GoHist( where )
  
  " nothing to do if history variable empty
  if empty(g:VTermHist)
    return 0
  endif
  
  
  " get cmd
  let l:cmd = strpart(getline('.'), (g:VTermPs1Len) , strlen(getline('.')))

  " save current cmd
  if len(g:VTermHist) == g:VTermCurId
    let s:VTermCurCmd = l:cmd
  endif
  
  let l:sub = ""
  
  " save alterations in the current history string
  if exists("g:VTermHist[".g:VTermCurId."]")
    let g:VTermHist[g:VTermCurId] = l:cmd
  endif
  
  if a:where == "prev" " treat prev history condition
    " dont let the CurId be lower than zero
    if g:VTermCurId < 1
      let g:VTermCurId = 1
    endif
    let g:VTermCurId -= 1
    
    let l:sub = g:VTermHist[g:VTermCurId]
    
  " treat next history condition
  elseif a:where == "next"
    
    " dont let the CurId be higher than the list len
    if g:VTermCurId >= len(g:VTermHist)
      let g:VTermCurId = len(g:VTermHist) - 1
    endif
    let g:VTermCurId += 1
    
    if exists("g:VTermHist[".g:VTermCurId."]") " do we have a next history?
      let l:sub = g:VTermHist[g:VTermCurId]
    else " if no history found, get the extra spaces
      let l:sub = s:VTermCurCmd
    endif
  endif
  
  " change the current cmd for the history cmd
  silent $d
  
  " print ps1 with the correspondent command
  call vterm#PutPs1( l:sub )
  "exec "silent $s/.*\\zs" . l:cmd . "/" . l:sub . "/"
  call cursor ( line('.'), col('$') )
endfunction

" function to manage the persistent insert mode
function! s:VTermPersistentInsert()
  if g:VTermPersistentInsert > 0
    startinsert
  endif
endfunction

" function to go to the start of the line
function! vterm#GoToStart()
  if line('.') == line('$')
    call cursor( line('.'),  g:VTermPs1Len + g:VTermExtraSpace)
  else
    call cursor( line('.'), 1)
  endif
endfunction

" clear history function
function! vterm#ClearHist()
  let g:VTermHist = []
  let g:VTermCurId = 0
endfunction
