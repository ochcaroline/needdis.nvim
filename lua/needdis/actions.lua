local M = {}

local api = vim.api

local file = require("needdis.file")
local state = require("needdis.state")
local utils = require("needdis.utils")
local config = require("needdis.config")

---@param fn function
local with_render = function(fn)
	fn()

	-- this is so that we don't have circular dependency
	require("needdis.render").render_todos()
end

---@param fn function
M.action_after_set_cursor = function(fn)
	local cursor = api.nvim_win_get_cursor(state.floats.body.win)
	fn()
	api.nvim_win_set_cursor(state.floats.body.win, cursor)
end

---@param title string
---@param description string
local add_todo = function(title, description)
	local todo = {
		title = title,
		completed = false,
		description = description,
	}
	table.insert(state.todos, todo)
end

---@param line string
local remove_todo = function(line)
	for i, todo in ipairs(state.todos) do
		if utils.get_title_from_line(line) == todo.title then
			table.remove(state.todos, i)
			break
		end
	end
end

---@param line string
local toggle_todo = function(line)
	for i, todo in ipairs(state.todos) do
		if utils.get_title_from_line(line) == todo.title then
			if state.todos[i].completed then
				state.todos[i].completed = false
			else
				state.todos[i].completed = true
			end
			break
		end
	end
end

---@param line string
---@param new_title string
local edit_todo_title = function(line, new_title)
	for i, todo in ipairs(state.todos) do
		if utils.get_title_from_line(line) == todo.title then
			state.todos[i].title = new_title
			break
		end
	end
end

---@param line string
---@param new_desc string
local edit_todo_description = function(line, new_desc)
	for i, todo in ipairs(state.todos) do
		if utils.get_title_from_line(line) == todo.title then
			if new_desc == nil then
				new_desc = ""
			end

			state.todos[i].description = new_desc
			break
		end
	end
end

M.new_todo = function()
	with_render(function()
		vim.ui.input({ prompt = config.options.messages.new_title }, function(title)
			if not title or title == "" then
				return
			end

			vim.ui.input({ prompt = config.options.messages.new_description }, function(description)
				add_todo(title, description or "")
			end)

			if M._winid and api.nvim_win_is_valid(M.state.floats.body.win) then
				api.nvim_set_current_win(M.state.floats.body.win)

				local lines_count = api.nvim_buf_line_count(M.state.floats.body.buf)

				api.nvim_win_set_cursor(M.state.floats.body.buf, { lines_count, 0 })
			end
		end)

		file.save_todos()
	end)
end

local get_current_cursor_pos_line_content = function()
	local cursor = api.nvim_win_get_cursor(state.floats.body.win)
	local todo_index = cursor[1] - 1
	local line_content = api.nvim_buf_get_lines(state.floats.body.buf, todo_index, todo_index + 1, false)[1]
	return line_content
end

M.delete_todo = function()
	with_render(function()
		local line_content = get_current_cursor_pos_line_content()
		remove_todo(line_content)
		file.save_todos()
	end)
end

M.toggle_todo = function()
	with_render(function()
		local line_content = get_current_cursor_pos_line_content()
		toggle_todo(line_content)
		file.save_todos()
	end)
end

M.edit_title = function()
	with_render(function()
		local line = get_current_cursor_pos_line_content()
		vim.ui.input(
			{ prompt = config.options.messages.edit_title, default = utils.get_title_from_line(line) },
			function(input)
				if not input or input == "" then
					vim.notify("Title cannot be empty!", vim.log.levels.WARN)
					return
				end
				edit_todo_title(line, input)
			end
		)
	end)
end

M.edit_description = function()
	with_render(function()
		local line = get_current_cursor_pos_line_content()
		vim.ui.input({ prompt = config.options.messages.edit_description }, function(input)
			edit_todo_description(line, input)
		end)
	end)
end

return M
