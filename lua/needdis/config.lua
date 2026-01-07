local M = {}

M.defaults = {
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
		move_task_up = "<leader>tk",
		move_task_down = "<leader>tj",
	},
	icons = {
		done = "✓",
	},
	messages = {
		title = "TODO List",
		todo_status_header = "TODO:",
		completed_status_header = "Completed:",
		no_items = "<no items>",
		no_description = "<no description>",
		new_title = "Add task title: ",
		new_description = "Add task description: ",
		edit_title = "Edited task title: ",
		edit_description = "Edited task description: ",
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
