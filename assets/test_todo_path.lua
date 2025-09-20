-- Test script to debug the todo file path resolution

-- Load the data module
local data = require('simple-todo.data')

-- Get git root function (copy from data.lua for testing)
local function get_git_root()
  -- Try to get git root from the current buffer's file path
  local current_file = vim.fn.expand('%:p')
  local cwd = vim.fn.getcwd()

  print("Current file: " .. current_file)
  print("Current working directory: " .. cwd)

  -- First try from the current file's directory
  if current_file ~= '' then
    local file_dir = vim.fn.fnamemodify(current_file, ':h')
    print("File directory: " .. file_dir)
    local handle = io.popen('cd "' .. file_dir .. '" && git rev-parse --show-toplevel 2>/dev/null')
    if handle then
      local result = handle:read("*l")
      handle:close()
      if result and result ~= "" then
        print("Git root from file dir: " .. result)
        return result
      end
    end
  end

  -- Fall back to checking from current working directory
  local handle = io.popen('cd "' .. cwd .. '" && git rev-parse --show-toplevel 2>/dev/null')
  if handle then
    local result = handle:read("*l")
    handle:close()
    if result and result ~= "" then
      print("Git root from cwd: " .. result)
      return result
    end
  end

  print("No git root found")
  return nil
end

-- Test get_todo_file function
local function test_get_todo_file()
  -- Check if user has explicitly set a file path
  if vim.g.simple_todo_file then
    print("User set file: " .. vim.g.simple_todo_file)
    return vim.g.simple_todo_file
  end

  -- Check if we're in a git repository
  local git_root = get_git_root()
  if git_root then
    local repo_todo_file = git_root .. '/.simple_todos.json'
    print("Checking for repo file: " .. repo_todo_file)
    local readable = vim.fn.filereadable(repo_todo_file)
    print("File readable (1=yes, 0=no): " .. readable)
    if readable == 1 then
      print("USING REPO FILE: " .. repo_todo_file)
      return repo_todo_file
    end
  end

  -- Fall back to the global todo file
  local global_file = vim.fn.stdpath('data') .. '/simple-todo.json'
  print("USING GLOBAL FILE: " .. global_file)
  return global_file
end

-- Run the test
print("=== Testing TODO file path resolution ===")
print("")
local result = test_get_todo_file()
print("")
print("Final result: " .. result)
print("")
print("=== Test complete ===")