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

M.list = function()
  ui.open_list()
end

M.add = function()
  ui.open_add()
end

M.delete = function()
  ui.open_delete()
end

return M