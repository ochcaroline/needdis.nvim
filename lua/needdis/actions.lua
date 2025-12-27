local M = {}

local api = vim.api

local file = require("needdis.file")
local state = require("needdis.state")
local utils = require("needdis.utils")

local add_todo = function(title)
	local todo = {
		title = title,
		completed = false,
		description = "",
	}
	table.insert(state.todos, todo)
end

local remove_todo = function(title)
	for i, todo in ipairs(state.todos) do
		if utils.strip(title) == todo.title then
			table.remove(state.todos, i)
			break
		end
	end
end

local toggle_todo = function(title)
	for i, todo in ipairs(state.todos) do
		if utils.strip(title:gsub("✓", "")) == todo.title then
			if state.todos[i].completed then
				state.todos[i].completed = false
			else
				state.todos[i].completed = true
			end
			break
		end
	end
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
	end)

	file.save_todos()
end

local get_current_cursor_pos_line_content = function()
	local cursor = api.nvim_win_get_cursor(state.floats.body.win)
	local todo_index = cursor[1] - 1
	local line_content = api.nvim_buf_get_lines(state.floats.body.buf, todo_index, todo_index + 1, false)[1]
	return line_content
end

M.delete_todo = function()
	local line_content = get_current_cursor_pos_line_content()

	remove_todo(line_content)

	file.save_todos()
end

M.toggle_todo = function()
	local line_content = get_current_cursor_pos_line_content()

	toggle_todo(line_content)

	file.save_todos()
end

return M
