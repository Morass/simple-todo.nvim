# simple-todo.nvim

A simple and lightweight TODO management plugin for Neovim.

**⚠️ Note:** This is a basic hobby plugin for personal use. Use at your own discretion.

<!-- ## Demo

![simple-todo.nvim demo](demo.gif) -->

## Features

- Simple popup window for TODO management
- Severity-based categorization with color coding
- Quick add, list, and delete functionality
- Persistent JSON storage
- Pure Lua/Neovim (no external dependencies)

## Installation

### Using vim-plug

```vim
Plug 'morass/simple-todo.nvim'
```

Then run `:PlugInstall`

### Using packer.nvim

```lua
use 'morass/simple-todo.nvim'
```

### Using lazy.nvim

```lua
{
  'morass/simple-todo.nvim',
  config = function()
    require('simple-todo').setup()
  end
}
```

## Usage

### Commands

- `:SimpleTodoToggle` - Open/close the TODO manager window

### Key Bindings

- `j`/`k` - Navigate up/down
- `Enter` - Select/confirm
- `q` - Go back/close
- `d` - Delete (in delete mode)
- `Escape` - Cancel text input

## Configuration

### Custom TODO storage location

By default, TODOs are stored in Neovim's data directory. You can customize this:

```vim
let g:simple_todo_file = '/path/to/your/todos.json'
```

Or in Lua:

```lua
require('simple-todo').setup({
  file = '/path/to/your/todos.json'
})
```

## Severity Levels

TODOs are color-coded by severity:
- **Critical** (Red) - Urgent tasks
- **Important** (Orange) - High priority tasks
- **Medium** (Green) - Normal priority tasks
- **Minor** (Gray) - Low priority tasks
- **Nice to Have** (Blue) - Optional tasks

## License

MIT