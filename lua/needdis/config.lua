local M = {}

M.defaults = {
	save_path = vim.fn.stdpath("data") .. "/needdis.json",
	keymaps = {
		add_todo = "<leader>ta",
		delete_todo = "<leader>td",
		toggle_completed = "<leader>tv",
		toggle_details = "<CR>",
	},
	icons = {
		done = "✓",
	},
	messages = {
		no_items = "<no items>",
		no_description = "<no description>",
		add_title = "Add TODO title: ",
		add_description = "Add TODO description: ",
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
