local M = {}
local ui = require('simple-todo.ui')
local data = require('simple-todo.data')

M.setup = function(opts)
  opts = opts or {}
  if opts.file then
    vim.g.simple_todo_file = opts.file
  end
end

M.toggle = function()
  ui.toggle()
end

return M