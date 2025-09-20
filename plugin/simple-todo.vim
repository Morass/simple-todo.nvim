" simple-todo.nvim - A simple TODO management plugin for Neovim
" Maintainer: Morass

if exists('g:loaded_simple_todo')
  finish
endif
let g:loaded_simple_todo = 1

" User configuration
if !exists('g:simple_todo_file')
  let g:simple_todo_file = stdpath('data') . '/simple-todo.json'
endif

" Commands
command! SimpleTodoToggle lua require('simple-todo').toggle()
command! SimpleTodoList lua require('simple-todo').list()
command! SimpleTodoAdd lua require('simple-todo').add()
command! SimpleTodoDelete lua require('simple-todo').delete()