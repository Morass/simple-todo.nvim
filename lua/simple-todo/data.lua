local M = {}

local severities = {
  critical = { priority = 1, color = 196, symbol = "●" },  -- bright red
  important = { priority = 2, color = 214, symbol = "●" },  -- orange/yellow
  medium = { priority = 3, color = 34, symbol = "●" },  -- green
  minor = { priority = 4, color = 245, symbol = "●" },  -- gray
  nice_to_have = { priority = 5, color = 39, symbol = "●" }  -- blue
}

M.severities = severities

local original_file_path = nil

local function get_git_root()
  local current_file = original_file_path or vim.fn.expand('%:p')

  if current_file and current_file ~= '' then
    local file_dir = vim.fn.fnamemodify(current_file, ':h')
    local handle = io.popen('cd "' .. file_dir .. '" && git rev-parse --show-toplevel 2>/dev/null')
    if handle then
      local result = handle:read("*l")
      handle:close()
      if result and result ~= "" then
        return result
      end
    end
  end

  return nil
end

M.set_original_file_path = function(path)
  original_file_path = path
end

local function get_todo_file()
  local git_root = get_git_root()
  if git_root then
    local repo_todo_file = git_root .. '/.simple_todos.json'
    if vim.fn.filereadable(repo_todo_file) == 1 then
      return repo_todo_file
    end
  end

  if vim.g.simple_todo_file then
    return vim.g.simple_todo_file
  end

  return vim.fn.stdpath('data') .. '/simple-todo.json'
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

  if not vim.g.simple_todo_file then
    local git_root = get_git_root()
    if git_root then
      local repo_todo_file = git_root .. '/.simple_todos.json'
      if vim.fn.filereadable(repo_todo_file) == 0 then
        file_path = repo_todo_file
      end
    end
  end

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
    created = os.time(),
    tags = {}
  })
  M.save_todos(todos)
end

M.delete_todo = function(todo_to_delete)
  local todos = M.load_todos()

  for i, todo in ipairs(todos) do
    if todo.text == todo_to_delete.text and
       todo.severity == todo_to_delete.severity and
       todo.created == todo_to_delete.created then
      table.remove(todos, i)
      M.save_todos(todos)
      return true, todos
    end
  end

  return false, nil
end

M.edit_todo = function(todo_to_edit, new_text)
  local todos = M.load_todos()

  for i, todo in ipairs(todos) do
    if todo.text == todo_to_edit.text and
       todo.severity == todo_to_edit.severity and
       todo.created == todo_to_edit.created then
      todos[i].text = new_text
      M.save_todos(todos)
      return true
    end
  end

  return false
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

M.edit_todo_tags = function(todo_to_edit, new_tags)
  local todos = M.load_todos()

  for i, todo in ipairs(todos) do
    if todo.text == todo_to_edit.text and
       todo.severity == todo_to_edit.severity and
       todo.created == todo_to_edit.created then
      todos[i].tags = new_tags
      M.save_todos(todos)
      return true
    end
  end

  return false
end

M.get_all_tags = function()
  local todos = M.load_todos()
  local tag_set = {}

  for _, todo in ipairs(todos) do
    if todo.tags then
      for _, tag in ipairs(todo.tags) do
        tag_set[tag] = true
      end
    end
  end

  local tags = {}
  for tag, _ in pairs(tag_set) do
    table.insert(tags, tag)
  end

  table.sort(tags)
  return tags
end

M.filter_todos_by_tag = function(tag_filter)
  local todos = M.load_todos()
  local filtered = {}

  for _, todo in ipairs(todos) do
    if todo.tags then
      for _, tag in ipairs(todo.tags) do
        if tag == tag_filter then
          table.insert(filtered, todo)
          break
        end
      end
    end
  end

  return sort_todos(filtered)
end

M.get_sorted_todos = function()
  local todos = M.load_todos()
  return sort_todos(todos)
end

M.sort_todos = sort_todos

return M