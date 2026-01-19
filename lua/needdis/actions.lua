local M = {}

local api = vim.api

local file = require("needdis.file")
local state = require("needdis.state")
local config = require("needdis.config")
local utils = require("needdis.utils")

---@param fn function
local function with_render(fn)
	fn()

	-- this is so that we don't have circular dependency
	require("needdis.render").render_todos()
end

---@param fn function
function M.action_after_set_cursor(fn)
	local cursor = api.nvim_win_get_cursor(state.floats.body.win)
	fn()
	api.nvim_win_set_cursor(state.floats.body.win, cursor)
end

---@param title string
---@param description string
---@param to_top boolean?
local function add_todo(title, description, to_top)
	if to_top == nil then
		to_top = true
	end

	local todo = {
		title = title,
		completed = false,
		description = description,
	}

	if to_top then
		table.insert(state.todos, 1, todo)
	else
		table.insert(state.todos, todo)
	end
end

---@param todo_idx integer
local function remove_todo(todo_idx)
	if todo_idx and state.todos[todo_idx] then
		table.remove(state.todos, todo_idx)
	end
end

---@param todo_idx integer
local function toggle_todo(todo_idx)
	if todo_idx and state.todos[todo_idx] then
		state.todos[todo_idx].completed = not state.todos[todo_idx].completed
	end
end

---@param todo_idx integer
---@param new_title string
local function edit_todo_title(todo_idx, new_title)
	if todo_idx and state.todos[todo_idx] then
		state.todos[todo_idx].title = new_title
	end
end

---@param todo_idx integer
---@param new_desc string
local function edit_todo_description(todo_idx, new_desc)
	if todo_idx and state.todos[todo_idx] then
		state.todos[todo_idx].description = new_desc
	end
end

function M.new_todo()
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
	utils.notify("New todo added!")
end

---@return integer|nil
local function get_todo_idx_at_cursor()
	local cursor = api.nvim_win_get_cursor(state.floats.body.win)
	local row = cursor[1] - 1

	local render = require("needdis.render")
	local marks = api.nvim_buf_get_extmarks(
		state.floats.body.buf,
		render.namespace,
		{ row, 0 },
		{ row, -1 },
		{ limit = 1 }
	)

	if marks and marks[1] then
		local mark_id = marks[1][1]
		local items_with_details = render.get_items_with_details()
		if items_with_details and items_with_details[mark_id] then
			return items_with_details[mark_id].idx
		end
	end
end

---@return integer|nil
local function safe_get_todo_idx()
	local todo_idx = get_todo_idx_at_cursor()
	if not todo_idx then
		vim.notify("No todo item at cursor", vim.log.levels.WARN)
		return
	end
	return todo_idx
end

function M.delete_todo()
	local todo_idx = safe_get_todo_idx()
	with_render(function()
		if todo_idx == nil then
			return
		end

		remove_todo(todo_idx)
		file.save_todos()
	end)
	utils.notify(string.format("TODO #%s deleted!", todo_idx))
end

function M.toggle_todo()
	with_render(function()
		local todo_idx = safe_get_todo_idx()
		if todo_idx == nil then
			return
		end

		toggle_todo(todo_idx)
		file.save_todos()
	end)
end

function M.edit_title()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	local current_title = state.todos[todo_idx].title
	vim.ui.input({ prompt = config.options.messages.edit_title, default = current_title }, function(input)
		if input == nil then
			return
		end

		with_render(function()
			edit_todo_title(todo_idx, input)
		end)
	end)
	utils.notify("Title changed!")
end

function M.edit_description()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	vim.ui.input({ prompt = config.options.messages.edit_description }, function(input)
		if input == nil then
			return
		end

		with_render(function()
			edit_todo_description(todo_idx, input)
		end)
	end)
	vim.notify("Description changed!")
end

---@param todo_idx integer
---@return boolean
local function is_completed(todo_idx)
	if state.todos[todo_idx].completed then
		vim.notify("Moving completed items is not possible", vim.log.levels.INFO)
		return true
	end
	return false
end

local function move_cursor_to_task(todo_idx)
	if state.floats.body.win and api.nvim_win_is_valid(state.floats.body.win) then
		local render = require("needdis.render")

		local items = render.get_items_with_details()
		for mark_id, details in pairs(items) do
			if details.idx == todo_idx then
				local marks = api.nvim_buf_get_extmarks(state.floats.body.buf, render.namespace, mark_id, mark_id, {})
				if marks[1] then
					local row = marks[1][2]
					api.nvim_win_set_cursor(state.floats.body.win, { row + 1, 0 })
				end
			end
		end
	end
end

function M.move_to_top()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	if is_completed(todo_idx) then
		return
	end

	if todo_idx == 1 then
		vim.notify("Task is already at the top!", vim.log.levels.INFO)
	end

	with_render(function()
		local todo = table.remove(state.todos, todo_idx)
		table.insert(state.todos, 1, todo)
		file.save_todos()
	end)

	vim.schedule(function()
		if state.floats.body.win and api.nvim_win_is_valid(state.floats.body.win) then
			api.nvim_win_set_cursor(state.floats.body.win, { 2, 0 })
		end
	end)

	utils.notify(string.format("TODO #%s moved to top!", todo_idx))
end

function M.move_to_bottom()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	if is_completed(todo_idx) then
		return
	end

	if todo_idx == #state.todos then
		vim.notify("Task is already at the bottom!", vim.log.levels.INFO)
	end

	with_render(function()
		local todo = table.remove(state.todos, todo_idx)
		table.insert(state.todos, todo)

		file.save_todos()
	end)

	vim.schedule(function()
		if state.floats.body.win and api.nvim_win_is_valid(state.floats.body.win) then
			local render = require("needdis.render")
			local last_idx = #state.todos
			local items = render.get_items_with_details()
			for mark_id, details in pairs(items) do
				if details.idx == last_idx then
					local marks =
						api.nvim_buf_get_extmarks(state.floats.body.buf, render.namespace, mark_id, mark_id, {})
					if marks[1] then
						local row = marks[1][2]
						api.nvim_win_set_cursor(state.floats.body.win, { row + 1, 0 })
					end
				end
			end
		end
	end)
	utils.notify(string.format("TODO #%s moved to bottom!", todo_idx))
end

function M.move_todo_up()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	if is_completed(todo_idx) then
		return
	end
	with_render(function()
		local todo = table.remove(state.todos, todo_idx)
		table.insert(state.todos, todo_idx - 1, todo)

		file.save_todos()
	end)

	vim.schedule(function()
		move_cursor_to_task(todo_idx - 1)
	end)
end

function M.move_todo_down()
	local todo_idx = safe_get_todo_idx()
	if todo_idx == nil then
		return
	end

	if is_completed(todo_idx) then
		return
	end

	with_render(function()
		local todo = table.remove(state.todos, todo_idx)
		table.insert(state.todos, todo_idx + 1, todo)

		file.save_todos()
	end)

	vim.schedule(function()
		move_cursor_to_task(todo_idx + 1)
	end)
end

return M
