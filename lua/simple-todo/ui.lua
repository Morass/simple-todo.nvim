local M = {}
local data = require('simple-todo.data')

local state = {
  buf = nil,
  win = nil,
  mode = "menu",
  todos = {},
  selected_severity = nil,
  ns_id = nil,
  edit_todo = nil,
  tag_todo = nil,
  all_tags = {},
  filter_tag = nil
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
    "  [LIST]    View all TODOs",
    "  [ADD]     Create new TODO",
    "  [DELETE]  Remove TODOs",
    "",
    "  Press Enter to select, q to quit"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  vim.api.nvim_set_hl(0, 'SimpleTodoMenuList', { ctermfg = 33 })  -- slightly lighter blue
  vim.api.nvim_set_hl(0, 'SimpleTodoMenuAdd', { ctermfg = 46 })   -- green
  vim.api.nvim_set_hl(0, 'SimpleTodoMenuDelete', { ctermfg = 88 }) -- red

  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuList', 3, 2, 8)
  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuAdd', 4, 2, 7)
  vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodoMenuDelete', 5, 2, 10)

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  vim.api.nvim_win_set_cursor(state.win, {4, 0})
end

local function render_list_with_todos(delete_mode, todos)
  state.todos = todos or data.get_sorted_todos()
  local header = ""
  if delete_mode then
    header = "  Delete TODO (press 'd' to delete, 'q' to go back)"
  elseif state.filter_tag then
    header = "  TODO List - Filtered by: " .. state.filter_tag .. " (press 'q' to go back)"
  else
    header = "  TODO List (press 'e' to edit, 't' for tags, 'f' to filter, 'q' to go back)"
  end

  local lines = {
    "",
    header,
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

  for i, todo in ipairs(state.todos) do
    local severity_info = data.severities[todo.severity]
    -- Create highlight group for this severity if not already created
    vim.api.nvim_set_hl(0, 'SimpleTodo' .. todo.severity, { ctermfg = severity_info.color })

    if delete_mode then
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodo' .. todo.severity, 3 + i - 1, 2, 3)
    else
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodo' .. todo.severity, 3 + i - 1, 2, 4)
    end
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  if #state.todos > 0 then
    vim.api.nvim_win_set_cursor(state.win, {4, 0})
  end
end

local function render_list(delete_mode)
  render_list_with_todos(delete_mode, nil)
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

  for i = 1, 5 do
    local severity_info = data.severities[severity_names[i]]

    vim.api.nvim_set_hl(0, 'SimpleTodo' .. severity_names[i], { ctermfg = severity_info.color })
    vim.api.nvim_buf_add_highlight(state.buf, -1, 'SimpleTodo' .. severity_names[i], 2 + i, 2, -1)
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  vim.api.nvim_win_set_cursor(state.win, {4, 0})
end

local function render_text_input()
  local lines = {
    "",
    state.edit_todo and "  Edit TODO text:" or "  Enter TODO text:",
    "",
    state.edit_todo and ("  " .. state.edit_todo.text) or "  ",
    "",
    "  Press Enter to save, Escape to cancel"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  local cursor_col = state.edit_todo and (2 + #state.edit_todo.text) or 2
  vim.api.nvim_win_set_cursor(state.win, {4, cursor_col})
  vim.cmd('startinsert')
end

local function render_tag_input()
  local lines = {
    "",
    "  Edit Tags (one per line):",
    "",
  }

  if state.tag_todo and state.tag_todo.tags then
    for _, tag in ipairs(state.tag_todo.tags) do
      table.insert(lines, "  " .. tag)
    end
  end

  table.insert(lines, "  ")
  table.insert(lines, "")
  table.insert(lines, "  Press Enter to save, Escape to cancel")

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  local cursor_row = #lines - 2
  vim.api.nvim_win_set_cursor(state.win, {cursor_row, 2})
  vim.cmd('startinsert')
end

local function render_filter_selection()
  local lines = {
    "",
    "  Select Tag to Filter:",
    "",
  }

  state.all_tags = data.get_all_tags()

  if #state.all_tags == 0 then
    table.insert(lines, "  No tags found")
  else
    for _, tag in ipairs(state.all_tags) do
      table.insert(lines, "  " .. tag)
    end
  end

  table.insert(lines, "")
  table.insert(lines, "  Press Enter to filter, 'q' to go back")

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  if #state.all_tags > 0 then
    vim.api.nvim_win_set_cursor(state.win, {4, 0})
  end
end

local function handle_menu_select()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local row = cursor[1]

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

  if row >= 4 and row <= 8 then
    local severity_names = {"critical", "important", "medium", "minor", "nice_to_have"}
    state.selected_severity = severity_names[row - 3]
    state.mode = "input"
    render_text_input()
  end
end

local function handle_text_input()
  local line = vim.api.nvim_buf_get_lines(state.buf, 3, 4, false)[1]
  local text = vim.trim(line)

  if text and text ~= "" then
    if state.edit_todo then
      data.edit_todo(state.edit_todo, text)
      state.edit_todo = nil
      vim.cmd('stopinsert')
      vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
      state.mode = "list"
      render_list(false)
      return
    else
      data.add_todo(text, state.selected_severity)
    end
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
    local todo_to_delete = state.todos[index]
    local success, updated_todos = data.delete_todo(todo_to_delete)
    if success then
      state.todos = data.sort_todos(updated_todos)
      render_list_with_todos(true, state.todos)
    end
  end
end

local function handle_edit()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local index = cursor[1] - 3

  if index > 0 and index <= #state.todos then
    state.edit_todo = state.todos[index]
    state.mode = "input"
    render_text_input()
  end
end

local function handle_tag_edit()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local index = cursor[1] - 3

  if index > 0 and index <= #state.todos then
    state.tag_todo = state.todos[index]
    state.mode = "tag_input"
    render_tag_input()
  end
end

local function handle_tag_input()
  local lines = vim.api.nvim_buf_get_lines(state.buf, 2, -3, false)
  local tags = {}

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      table.insert(tags, trimmed)
    end
  end

  if state.tag_todo then
    data.edit_todo_tags(state.tag_todo, tags)
    state.tag_todo = nil
  end

  vim.cmd('stopinsert')
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  state.mode = "list"
  render_list(false)
end

local function handle_filter_select()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local index = cursor[1] - 3

  if index > 0 and index <= #state.all_tags then
    state.filter_tag = state.all_tags[index]
    local filtered_todos = data.filter_todos_by_tag(state.filter_tag)
    state.mode = "list"
    render_list_with_todos(false, filtered_todos)
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
    elseif state.mode == "list" and state.filter_tag then
      state.filter_tag = nil
      state.mode = "list"
      render_list(false)
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
    elseif state.mode == "filter" then
      handle_filter_select()
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
    elseif state.mode == "filter" then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      local max_row = math.min(4 + #state.all_tags - 1, vim.api.nvim_buf_line_count(state.buf) - 2)
      if cursor[1] < max_row then
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
    elseif state.mode == "filter" then
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

  map('e', function()
    if state.mode == "list" then
      handle_edit()
    end
  end)

  map('t', function()
    if state.mode == "list" then
      handle_tag_edit()
    end
  end)

  map('f', function()
    if state.mode == "list" and not state.filter_tag then
      state.mode = "filter"
      render_filter_selection()
    end
  end)

  vim.api.nvim_buf_set_keymap(state.buf, 'i', '<CR>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if state.mode == "input" then
        handle_text_input()
      elseif state.mode == "tag_input" then
        handle_tag_input()
      end
    end
  })

  vim.api.nvim_buf_set_keymap(state.buf, 'i', '<Esc>', '', {
    noremap = true,
    silent = true,
    callback = function()
      vim.cmd('stopinsert')
      vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
      if state.edit_todo then
        state.edit_todo = nil
        state.mode = "list"
        render_list(false)
      elseif state.tag_todo then
        state.tag_todo = nil
        state.mode = "list"
        render_list(false)
      else
        state.mode = "menu"
        render_menu()
      end
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
  data.set_original_file_path(vim.fn.expand('%:p'))

  state.buf, state.win = create_window()
  state.mode = "menu"

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

M.open_list = function()
  data.set_original_file_path(vim.fn.expand('%:p'))

  state.buf, state.win = create_window()
  state.mode = "list"

  if not state.ns_id then
    state.ns_id = vim.api.nvim_create_namespace('simple-todo')
  end

  setup_keymaps()
  render_list(false)
end

M.open_add = function()
  data.set_original_file_path(vim.fn.expand('%:p'))

  state.buf, state.win = create_window()
  state.mode = "severity"

  if not state.ns_id then
    state.ns_id = vim.api.nvim_create_namespace('simple-todo')
  end

  setup_keymaps()
  render_severity_selection()
end

M.open_delete = function()
  data.set_original_file_path(vim.fn.expand('%:p'))

  state.buf, state.win = create_window()
  state.mode = "delete"

  if not state.ns_id then
    state.ns_id = vim.api.nvim_create_namespace('simple-todo')
  end

  setup_keymaps()
  render_list(true)
end

return M