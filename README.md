# simple-todo.nvim

A simple and lightweight TODO management plugin for Neovim.

**⚠️ Note:** This is a basic hobby plugin for personal use. Use at your own discretion.

## Features

- Simple popup window for TODO management
- Severity-based categorization and color coding
- Quick add, list, and delete functionality
- Persistent storage in JSON format
- Minimal dependencies (pure Lua/Neovim)

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

### Navigation

**Main Menu:**
- `j`/`k` or arrow keys - Navigate menu options
- `Enter` - Select option
- `q` - Close window

**List View:**
- `j`/`k` - Scroll through TODOs
- `q` - Back to menu

**Add TODO:**
1. Select severity level (Critical, Important, Medium, Minor, Nice to Have)
2. Type your TODO text
3. Press `Enter` to save or `Escape` to cancel

**Delete TODO:**
- Navigate to the TODO you want to delete
- Press `d` to delete
- Press `q` to go back

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
- **Critical** (Dark Red) - Urgent tasks
- **Important** (Yellow) - High priority
- **Medium** (Green) - Normal priority
- **Minor** (Gray) - Low priority
- **Nice to Have** (Blue) - Optional tasks

## License

MIT