#vterm : Terminal emulator inside vim.
=====

##Intro
The goal of verun is to provide a clone of unix terminal inside vim without
any dependencies.

##Instalation
Use your favorite package manager to install it or place `autoload` and `plugin`
folders in your ~/.vim directory.

##Start
To start vterm, run
```
:VTermStart
```

##Configuration
###History
VTerm keeps you search history. You can call the previous and next commands by pressing
<C-p> and <C-n> respectively. If you wish you can change the mappings by setting the
following variables:
```
let g:VTermKeyPrevHist="<C-p>" " call previouns command in history
let g:VTermKeyNextHist="<C-n>" " call next command in history
```

###PS1 variable
You can customize the ps1 variable by changing the following variable:
```
let g:VTermPs1 = "[%U@%H %D] $"
```
  
	%U is your username
	%H is your hostname
	%D is the working directory

###Persistent insert
If this variable is non-zero, VTerm will enter automatic in insert mode when start VTerm and
after entering your commands.
```
let g:VTermPersistentInsert=1
```
