local M = {}
local data = require('simple-todo.data')

local state = {
  buf = nil,
  win = nil,
  mode = "menu",
  todos = {},
  selected_severity = nil
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
    "  [ List ]    View all todos",
    "  [ Add ]     Create new todo",
    "  [ Delete ]  Remove todos",
    "",
    "  Press Enter to select, q to quit"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
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

    if not delete_mode then
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'Normal', #lines - 1, 2, 4)
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'Normal', #lines - 1, 0, -1)
      vim.api.nvim_buf_set_extmark(state.buf, 0, #lines - 1, 2, {
        virt_text = {{symbol, {fg = severity_info.color}}},
        virt_text_pos = 'overlay'
      })
    end
  end

  if #state.todos == 0 then
    table.insert(lines, "  No todos yet!")
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
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
    "  [ Critical ]     Urgent, must be done ASAP",
    "  [ Important ]    High priority task",
    "  [ Medium ]       Normal priority task",
    "  [ Minor ]        Low priority task",
    "  [ Nice to Have ] Would be good to do",
    "",
    "  Press Enter to select, q to cancel"
  }

  local severity_names = {"critical", "important", "medium", "minor", "nice_to_have"}

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  for i = 1, 5 do
    local severity_info = data.severities[severity_names[i]]
    vim.api.nvim_buf_add_highlight(state.buf, -1, 'Normal', 2 + i, 0, -1)
    vim.api.nvim_buf_set_extmark(state.buf, 0, 2 + i, 2, {
      virt_text = {{"[", "Normal"}, {" " .. severity_names[i]:gsub("_", " "):gsub("^%l", string.upper) .. " ", {fg = severity_info.color}}, {"]", "Normal"}},
      virt_text_pos = 'overlay'
    })
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  vim.api.nvim_win_set_cursor(state.win, {4, 0})  -- Start at first severity option
end

local function render_text_input()
  local lines = {
    "",
    "  Enter TODO text:",
    "",
    "  > ",
    "",
    "  Press Enter to save, Escape to cancel"
  }

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  vim.api.nvim_win_set_cursor(state.win, {4, 4})
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
  local text = line:sub(5)

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