local M = {}

local severities = {
  critical = { priority = 1, color = 196, symbol = "●" },  -- bright red
  important = { priority = 2, color = 214, symbol = "●" },  -- orange/yellow
  medium = { priority = 3, color = 34, symbol = "●" },  -- green
  minor = { priority = 4, color = 245, symbol = "●" },  -- gray
  nice_to_have = { priority = 5, color = 39, symbol = "●" }  -- blue
}

M.severities = severities

-- Store the original buffer's file path when the module loads
-- This will be updated each time before we open the UI
local original_file_path = nil

local function get_git_root()
  -- Use the stored original file path if available, otherwise try current buffer
  local current_file = original_file_path or vim.fn.expand('%:p')

  -- Only try from the file's directory if we have a valid file
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

  -- No file-based git root found
  return nil
end

-- Function to update the original file path (called before opening UI)
M.set_original_file_path = function(path)
  original_file_path = path
end

local function get_todo_file()
  -- Priority 1: Check if we're in a git repository with .simple_todos.json
  local git_root = get_git_root()
  if git_root then
    local repo_todo_file = git_root .. '/.simple_todos.json'
    -- Check if the repo-specific file exists using Vim's filereadable
    if vim.fn.filereadable(repo_todo_file) == 1 then
      return repo_todo_file
    end
  end

  -- Priority 2: Check if user has explicitly set a file path
  if vim.g.simple_todo_file then
    return vim.g.simple_todo_file
  end

  -- Priority 3: Fall back to the global todo file
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

  -- If we're in a git repo and no repo-specific file exists yet,
  -- and no explicit path was set, create the repo-specific file
  if not vim.g.simple_todo_file then
    local git_root = get_git_root()
    if git_root then
      local repo_todo_file = git_root .. '/.simple_todos.json'
      -- Check if the repo-specific file doesn't exist yet
      if vim.fn.filereadable(repo_todo_file) == 0 then
        -- Use the repo-specific path for new saves
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

-- Debug function to check which file is being used
M.get_current_todo_file = function()
  -- Debug info BEFORE calling get_todo_file
  local current_file = original_file_path or vim.fn.expand('%:p')
  print("\n=== TODO File Debug ===")
  print("Current buffer file: " .. vim.fn.expand('%:p'))
  print("Original file path stored: " .. (original_file_path or "none"))
  print("Will check from file: " .. (current_file ~= '' and current_file or "none"))

  local git_root = get_git_root()
  local repo_file = git_root and (git_root .. '/.simple_todos.json') or nil
  local repo_exists = repo_file and vim.fn.filereadable(repo_file) or 0

  print("Git root detected: " .. (git_root or "none"))
  if repo_file then
    print("Repo file path: " .. repo_file)
    print("Repo file exists: " .. (repo_exists == 1 and "YES" or "NO"))
  else
    print("Repo file: none (not in git repo)")
  end

  print("g:simple_todo_file set to: " .. (vim.g.simple_todo_file or "not set"))

  -- Now call the actual function
  local result = get_todo_file()
  print("\nFINAL DECISION: " .. result)

  -- Explain why this file was chosen
  if repo_file and repo_exists == 1 then
    if result == repo_file then
      print("✓ Using repo file (highest priority)")
    else
      print("✗ ERROR: Should be using repo file but using something else!")
    end
  elseif vim.g.simple_todo_file and result == vim.g.simple_todo_file then
    print("✓ Using custom g:simple_todo_file (repo file doesn't exist)")
  elseif result == vim.fn.stdpath('data') .. '/simple-todo.json' then
    print("✓ Using global default (no repo file, no custom setting)")
  end

  print("======================\n")
  return result
end

return M