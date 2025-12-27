local M = {}

local api = vim.api

local file = require("needdis.file")

local add_todo = function(title)
	local todo = {
		title = title,
		completed = false,
		description = "",
	}
	table.insert(M.state.todos, todo)
end

M.new_todo = function()
	vim.ui.input({ prompt = "Add TODO:" }, function(input)
		if not input or input == "" then
			return
		end

		add_todo(input)

		if M._winid and api.nvim_win_is_valid(M.state.floats.body.win) then
			api.nvim_set_current_win(M.state.floats.body.win)

			local lines_count = api.nvim_buf_line_count(M.state.floats.body.buf)

			api.nvim_win_set_cursor(M.state.floats.body.buf, { lines_count, 0 })
		end

		M.render_todos()
	end)

	file.save_todos()
end

M.delete_todo = function()
	local cursor = api.nvim_win_get_cursor(M.state.floats.body.win)
	local todo_index = cursor[1]
	local line_content = api.nvim_buf_get_lines(M.state.floats.body.buf, todo_index, todo_index + 1, false)[1]
end

return M
