# needdis.nvim

## Reasoning
I tried multiple apps for tracking my tasks - Microsoft ToDo, Obsidian etc. After trying them I decided it would be VERY GOOD IDEA to write a lua plugin on my own.
This is because I do not want to switch programs to keep order of my tasks.

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
|--------------|------------------------------------------|
| `<leader>at` | Toggle view of all tasks (toggle window) |

### TODO window keymaps
| Keymap       	| Action                 	|
|---------------|------------------------	|
| `<CR>`    	| Toggle task details       |
| `<leader>ta` 	| Add task               	|
| `<leader>td` 	| Delete task            	|
| `<leader>tv` 	| Toggle task completion 	|
| `<leader>tet`	| Change task title         |
| `<leader>ted`	| Change task description   |
