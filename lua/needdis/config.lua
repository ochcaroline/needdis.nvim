local M = {}

M.defaults = {
	save_path = vim.fn.stdpath("data") .. "/needdis.json",
	keymaps = {
		add_todo = "<leader>ta",
		delete_todo = "<leader>td",
		mark_completed = "<leader>tv",
		toggle_details = "<CR>",
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
