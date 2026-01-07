# needdis.nvim

Another neovim plugin that does tracking of your personal tasks.

## Reasoning

I tried multiple apps for tracking my tasks - Microsoft ToDo, Obsidian etc. Every one of them needed me to leave the terminal and I do not want that. I want to be able to do it in program that I use the most - neovim.
So I did nvim plugin to handle that for me.

**ℹ️ Note**: This plugin is very opinionated, because it's designed to match what I need. PRs appreciated though

![image](./docs/img/shot.jpeg)

## Installation

Lazy:

```lua
return { "ochcaroline/needdis.nvim" }
```

## Usage

### Global keymaps

| Keymap       | Action                                   |
| ------------ | ---------------------------------------- |
| `<leader>at` | Toggle view of all tasks (toggle window) |

### TODO window keymaps

| Keymap        | Action                  |
| ------------- | ----------------------- |
| `<CR>`        | Toggle task details     |
| `<leader>ta`  | Add task                |
| `<leader>td`  | Delete task             |
| `<leader>tv`  | Toggle task completion  |
| `<leader>tet` | Change task title       |
| `<leader>ted` | Change task description |
| `<leader>tt`  | Move task to top        |
| `<leader>tb`  | Move task to bottom     |

## Configuration

Default configuration:

```lua
{
	save_path = vim.fn.stdpath("data") .. "/needdis.json",
	keymaps = {
		toggle_window = "<leader>at",
		add_todo = "<leader>ta",
		delete_todo = "<leader>td",
		toggle_completed = "<leader>tv",
		toggle_details = "<CR>",
		edit_title = "<leader>tet",
		edit_description = "<leader>ted",
		move_to_top = "<leader>tt",
		move_to_bottom = "<leader>tb",
	},
	icons = {
		done = "✓",
	},
	messages = {
		title = "TODO List",
		no_items = "<no items>",
		no_description = "<no description>",
		new_title = "Add task title: ",
		new_description = "Add task description: ",
		edit_title = "Edited task title: ",
		edit_description = "Edited task description: ",
	},
}
```
