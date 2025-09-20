# simple-todo.nvim

A simple and lightweight TODO management plugin for Neovim.

**⚠️ Note:** This is a basic hobby plugin for personal use. Use at your own discretion.

**🎨 Color Note:** This plugin uses terminal colors (ctermfg) for highlighting, which means appearance depends on your terminal's color scheme. If colors don't display correctly or you prefer GUI colors, this plugin might not be ideal for your setup.

## Demo

![simple-todo.nvim demo](assets/demo.gif)

![simple-todo.nvim screenshot](assets/demo.png)

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
- `:SimpleTodoList` - Open the TODO manager directly in list view
- `:SimpleTodoAdd` - Open the TODO manager directly in add mode
- `:SimpleTodoDelete` - Open the TODO manager directly in delete mode

### Key Bindings

- `j`/`k` - Navigate up/down
- `Enter` - Select/confirm
- `q` - Go back/close
- `d` - Delete (in delete mode)
- `Escape` - Cancel text input

## Configuration

### TODO Storage Location

The plugin uses a smart storage system that automatically determines where to save your TODOs:

1. **Repository-specific storage** (automatic): If you're working in a git repository, the plugin will automatically use `.simple_todos.json` in the repository root if it exists. This allows you to have project-specific TODOs that can be committed to the repository (or git-ignored if preferred).

2. **Global storage** (default): When not in a git repository or if no `.simple_todos.json` exists in the repo, TODOs are stored in Neovim's data directory at `~/.local/share/nvim/simple-todo.json` (location varies by OS).

3. **Custom location** (manual): You can override the automatic behavior by setting a custom path:

```vim
let g:simple_todo_file = '/path/to/your/todos.json'
```

Or in Lua:

```lua
require('simple-todo').setup({
  file = '/path/to/your/todos.json'
})
```

### Repository-specific TODOs

To use repository-specific TODOs:
- Simply create your first TODO while in a git repository - the plugin will automatically create `.simple_todos.json` in the repository root
- Add `.simple_todos.json` to `.gitignore` if you want to keep TODOs local
- Or commit `.simple_todos.json` to share project TODOs with your team

## Severity Levels

TODOs are color-coded by severity:
- **Critical** (Red) - Urgent tasks
- **Important** (Orange) - High priority tasks
- **Medium** (Green) - Normal priority tasks
- **Minor** (Gray) - Low priority tasks
- **Nice to Have** (Blue) - Optional tasks

## Alternative TODO Plugins

If you need more advanced features, consider these excellent alternatives:

- [**todo-comments.nvim**](https://github.com/folke/todo-comments.nvim) - Highlight and search TODO comments in your code
- [**vim-todo-lists**](https://github.com/aserebryakov/vim-todo-lists) - TODO lists with checkbox support
- [**dooing**](https://github.com/atiladefreitas/dooing) - A more feature-rich TODO manager with categories and persistence
- [**taskwiki**](https://github.com/tools-life/taskwiki) - Combines vim wiki with Taskwarrior for advanced task management
- [**vimwiki**](https://github.com/vimwiki/vimwiki) - Personal wiki with TODO list capabilities

## License

MIT