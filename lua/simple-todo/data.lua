local M = {}

local severities = {
  critical = { priority = 1, color = 196, symbol = "●" },  -- bright red
  important = { priority = 2, color = 214, symbol = "●" },  -- orange/yellow
  medium = { priority = 3, color = 34, symbol = "●" },  -- green
  minor = { priority = 4, color = 245, symbol = "●" },  -- gray
  nice_to_have = { priority = 5, color = 39, symbol = "●" }  -- blue
}

M.severities = severities

local function get_todo_file()
  return vim.g.simple_todo_file or (vim.fn.stdpath('data') .. '/simple-todo.json')
end

M.load_todos = function()
  local file_path = get_todo_file()
  local file = io.open(file_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  if content == "" then
    return {}
  end

  local ok, todos = pcall(vim.json.decode, content)
  if not ok then
    return {}
  end

  return todos or {}
end

M.save_todos = function(todos)
  local file_path = get_todo_file()
  local file = io.open(file_path, "w")
  if not file then
    vim.notify("Failed to save todos", vim.log.levels.ERROR)
    return
  end

  file:write(vim.json.encode(todos))
  file:close()
end

M.add_todo = function(text, severity)
  local todos = M.load_todos()
  table.insert(todos, {
    text = text,
    severity = severity,
    created = os.time()
  })
  M.save_todos(todos)
end

M.delete_todo = function(todo_to_delete)
  local todos = M.load_todos()

  -- Find the TODO in the original array by matching text, severity, and created time
  for i, todo in ipairs(todos) do
    if todo.text == todo_to_delete.text and
       todo.severity == todo_to_delete.severity and
       todo.created == todo_to_delete.created then
      table.remove(todos, i)
      M.save_todos(todos)
      return true, todos -- Return the updated list to avoid re-reading
    end
  end

  return false, nil -- TODO not found
end

local function sort_todos(todos)
  table.sort(todos, function(a, b)
    local a_priority = severities[a.severity].priority
    local b_priority = severities[b.severity].priority

    if a_priority == b_priority then
      return a.created > b.created
    end
    return a_priority < b_priority
  end)
  return todos
end

M.get_sorted_todos = function()
  local todos = M.load_todos()
  return sort_todos(todos)
end

M.sort_todos = sort_todos

return M