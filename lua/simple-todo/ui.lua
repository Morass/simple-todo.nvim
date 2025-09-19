local M = {}
local data = require('simple-todo.data')

local state = {
  buf = nil,
  win = nil,
  mode = "menu",
  todos = {},
  selected_severity = nil,
  ns_id = nil
}

local function create_window()
  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.5)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  return buf, win
end

local function render_menu()
  local lines = {
    "",
    "  Simple TODO Manager",
    "",
    "  [LIST]    View all todos",
    "  [ADD]     Create new todo",
    "  [DELETE]  Remove todos",
    "",
    "  Press Enter to select, q to quit"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply colors to menu options
  vim.api.nvim_set_hl(0, 'SimpleTodoMenuList', { ctermfg = 21 })  -- blue
  vim.api.nvim_set_hl(0, 'SimpleTodoMenuAdd', { ctermfg = 46 })   -- green
  vim.api.nvim_set_hl(0, 'SimpleTodoMenuDelete', { ctermfg = 88 }) -- red

  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuList', 3, 2, 8)
  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuAdd', 4, 2, 7)
  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuDelete', 5, 2, 10)

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  vim.api.nvim_win_set_cursor(state.win, {4, 0})  -- Start at first menu option
end

local function render_list(delete_mode)
  state.todos = data.get_sorted_todos()
  local lines = {
    "",
    delete_mode and "  Delete TODO (press 'd' to delete, q to go back)" or "  TODO List (press q to go back)",
    ""
  }

  for i, todo in ipairs(state.todos) do
    local severity_info = data.severities[todo.severity]
    local symbol = delete_mode and "✗" or severity_info.symbol
    local line = string.format("  %s %s", symbol, todo.text)
    table.insert(lines, line)
  end

  if #state.todos == 0 then
    table.insert(lines, "  No active TODO(s)")
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply colors to TODO bullets or delete crosses
  if delete_mode then
    -- Color crosses in red for delete mode
    vim.api.nvim_set_hl(0, 'SimpleTodoDeleteCross', { ctermfg = 196 })  -- bright red
    for i, todo in ipairs(state.todos) do
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoDeleteCross', 2 + i, 2, 3)
    end
  else
    -- Color bullets according to severity
    for i, todo in ipairs(state.todos) do
      local severity_info = data.severities[todo.severity]
      -- Create highlight group for this severity if not already created
      vim.api.nvim_set_hl(0, 'SimpleTodo' .. todo.severity, { ctermfg = severity_info.color })
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodo' .. todo.severity, 2 + i, 2, 4)
    end
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  if #state.todos > 0 then
    vim.api.nvim_win_set_cursor(state.win, {4, 0})
  end
end

local function render_severity_selection()
  local lines = {
    "",
    "  Select TODO Severity:",
    "",
    "  Critical",
    "  Important",
    "  Medium",
    "  Minor",
    "  Nice to Have",
    "",
    "  Press Enter to select, q to cancel"
  }

  local severity_names = {"critical", "important", "medium", "minor", "nice_to_have"}

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply colors to severity names
  for i = 1, 5 do
    local severity_info = data.severities[severity_names[i]]

    -- Create highlight group for this severity
    vim.api.nvim_set_hl(0, 'SimpleTodo' .. severity_names[i], { ctermfg = severity_info.color })
    vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodo' .. severity_names[i], 2 + i, 2, -1)
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  vim.api.nvim_win_set_cursor(state.win, {4, 0})  -- Start at first severity option
end

local function render_text_input()
  local lines = {
    "",
    "  Enter TODO text:",
    "",
    "  ",
    "",
    "  Press Enter to save, Escape to cancel"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  vim.api.nvim_win_set_cursor(state.win, {4, 2})  -- Position at beginning of input line
  vim.cmd('startinsert')
end

local function handle_menu_select()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local row = cursor[1]

  -- Menu options are on lines 4, 5, 6
  if row == 4 then
    state.mode = "list"
    render_list(false)
  elseif row == 5 then
    state.mode = "severity"
    render_severity_selection()
  elseif row == 6 then
    state.mode = "delete"
    render_list(true)
  end
end

local function handle_severity_select()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local row = cursor[1]

  -- Severity options are on lines 4-8
  if row >= 4 and row <= 8 then
    local severity_names = {"critical", "important", "medium", "minor", "nice_to_have"}
    state.selected_severity = severity_names[row - 3]
    state.mode = "input"
    render_text_input()
  end
end

local function handle_text_input()
  local line = vim.api.nvim_buf_get_lines(state.buf, 3, 4, false)[1]
  local text = vim.trim(line)  -- Just trim the whole line

  if text and text ~= "" then
    data.add_todo(text, state.selected_severity)
  end

  vim.cmd('stopinsert')
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  state.mode = "menu"
  render_menu()
end

local function handle_delete()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local index = cursor[1] - 3

  if index > 0 and index <= #state.todos then
    data.delete_todo(index)
    render_list(true)
  end
end

local function setup_keymaps()
  local function map(key, callback)
    vim.api.nvim_buf_set_keymap(state.buf, 'n', key, '', {
      noremap = true,
      silent = true,
      callback = callback
    })
  end

  map('q', function()
    if state.mode == "menu" then
      M.close()
    else
      state.mode = "menu"
      render_menu()
    end
  end)

  map('<CR>', function()
    if state.mode == "menu" then
      handle_menu_select()
    elseif state.mode == "severity" then
      handle_severity_select()
    end
  end)

  map('j', function()
    if state.mode == "menu" then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      if cursor[1] < 6 then
        vim.api.nvim_win_set_cursor(state.win, {cursor[1] + 1, 0})
      end
    elseif state.mode == "severity" then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      if cursor[1] < 8 then
        vim.api.nvim_win_set_cursor(state.win, {cursor[1] + 1, 0})
      end
    elseif (state.mode == "list" or state.mode == "delete") then
      vim.cmd('normal! j')
    end
  end)

  map('k', function()
    if state.mode == "menu" then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      if cursor[1] > 4 then
        vim.api.nvim_win_set_cursor(state.win, {cursor[1] - 1, 0})
      end
    elseif state.mode == "severity" then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      if cursor[1] > 4 then
        vim.api.nvim_win_set_cursor(state.win, {cursor[1] - 1, 0})
      end
    elseif (state.mode == "list" or state.mode == "delete") then
      vim.cmd('normal! k')
    end
  end)

  map('d', function()
    if state.mode == "delete" then
      handle_delete()
    end
  end)

  vim.api.nvim_buf_set_keymap(state.buf, 'i', '<CR>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if state.mode == "input" then
        handle_text_input()
      end
    end
  })

  vim.api.nvim_buf_set_keymap(state.buf, 'i', '<Esc>', '', {
    noremap = true,
    silent = true,
    callback = function()
      vim.cmd('stopinsert')
      state.mode = "menu"
      render_menu()
    end
  })
end

M.toggle = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

M.open = function()
  state.buf, state.win = create_window()
  state.mode = "menu"

  -- Create namespace for extmarks if needed
  if not state.ns_id then
    state.ns_id = vim.api.nvim_create_namespace('simple-todo')
  end

  setup_keymaps()
  render_menu()
end

M.close = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.buf = nil
  state.win = nil
  state.mode = "menu"
end

return M