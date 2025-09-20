" simple-todo.nvim - A simple TODO management plugin for Neovim
" Maintainer: Morass

if exists('g:loaded_simple_todo')
  finish
endif
let g:loaded_simple_todo = 1

" User configuration
" Note: g:simple_todo_file is now optional - only set if you want to override automatic detection

" Commands
command! SimpleTodoToggle lua require('simple-todo').toggle()
command! SimpleTodoList lua require('simple-todo').list()
command! SimpleTodoAdd lua require('simple-todo').add()
command! SimpleTodoDelete lua require('simple-todo').delete()
command! SimpleTodoDebug lua print("Using TODO file: " .. require('simple-todo.data').get_current_todo_file())