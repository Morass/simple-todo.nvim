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
- Quick add, list, edit, delete, and tag functionality
- Tag-based filtering and organization
- Persistent JSON storage
- Pure Lua/Neovim (no external dependencies)

## Installation

### Using vim-plug

```vim
Plug 'morass/simple-todo.nvim'
```

To use the latest development version with edit functionality:
```vim
Plug 'morass/simple-todo.nvim', { 'branch': 'feat/edit-functionality' }
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
- `e` - Edit TODO text (in list mode)
- `t` - Edit tags (in list mode)
- `f` - Filter by tag (in list mode)
- `d` - Delete (in delete mode)
- `Escape` - Cancel text input

### Edit Functionality

The edit feature allows you to modify existing TODO items while preserving all attributes except the text content:

1. Navigate to any TODO item in list view
2. Press `e` to enter edit mode
3. The text input window opens with the current TODO text pre-filled
4. Modify the text as needed
5. Press `Enter` to save changes or `Escape` to cancel
6. All other attributes (severity level, creation time, tags) remain unchanged

### Tag System

The tag system allows you to organize and filter your TODO items:

**Adding/Editing Tags:**
1. Navigate to any TODO item in list view
2. Press `t` to enter tag edit mode
3. Enter tags separated by commas (e.g., "bug, evening event, feature")
4. Press `Enter` to save tags or `Escape` to cancel

**Filtering by Tags:**
1. In list view, press `f` to open the filter screen
2. All existing tags are displayed alphabetically
3. Press `Enter` on any tag to filter the list
4. Press `q` to return to the unfiltered list

Tags are stored as part of each TODO item and persist across sessions.

## Configuration

### TODO Storage Location

The plugin uses a smart storage system that automatically determines where to save your TODOs, with the following priority order:

1. **Repository-specific storage** (highest priority): If you're editing a file in a git repository and `.simple_todos.json` exists in the repository root, it will always be used. This ensures project-specific TODOs are always preferred.

2. **Custom location** (medium priority): If you've set `g:simple_todo_file`, it will be used when no repository-specific file exists.

3. **Global storage** (lowest priority): When not in a git repository or if no `.simple_todos.json` exists in the repo, TODOs are stored in Neovim's data directory at `~/.local/share/nvim/simple-todo.json` (location varies by OS).

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
