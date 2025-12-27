local M = {}

local api = vim.api

local state = require("needdis.state")
local actions = require("needdis.actions")
local utils = require("needdis.utils")
local config = require("needdis.config")

M.namespace = api.nvim_create_namespace("needdisns")
M.namespace_hl = api.nvim_create_namespace("needdis_hl")
M.current_context = "global"

api.nvim_set_hl(0, "TodoDone", { fg = "#696969", strikethrough = true })
api.nvim_set_hl(0, "TodoDescription", { fg = "#656565", italic = true })

local items_with_details = {}
local task_done_pattern = "✓+%s+"

local get_window_config = function()
	local width = vim.o.columns
	local height = vim.o.lines

	local window_width = 100
	local header_height = 1 + 2 -- 1 + border
	local body_height = height - header_height - 2 - 1 - 10

	return {
		header = {
			relative = "editor",
			width = window_width,
			height = 1,
			style = "minimal",
			border = "rounded",
			col = math.floor((width - window_width) / 2),
			row = 6,
			zindex = 2,
		},
		body = {
			relative = "editor",
			width = window_width,
			height = body_height,
			style = "minimal",
			border = "rounded",
			-- border = { " ", " ", " ", " ", " ", " ", " ", " " },
			col = math.floor((width - window_width) / 2),
			row = 8,
		},
	}
end

local create_window = function(cfg, enter)
	if enter == nil then
		enter = false
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(bufnr, enter or false, cfg)

	return { buf = bufnr, win = win }
end

local foreach_float = function(cb)
	for name, float in pairs(state.floats) do
		cb(name, float)
	end
end

local title_line = function(item)
	return string.format("%s %s", item.completed and "✓" or " ", item.title)
end

local is_done_task = function(line)
	return line:match(task_done_pattern)
end
local extmark_on_row = function(row)
	local marks = api.nvim_buf_get_extmarks(state.floats.body.buf, M.namespace, { row, 0 }, { row, 1 }, { limit = 1 })
	if marks and marks[1] then
		return marks[1][1]
	end
	return nil
end

local function extmark_row_by_id(mark_id)
	if not mark_id then
		return nil
	end
	local marks = api.nvim_buf_get_extmarks(state.floats.body.buf, M.namespace, 0, -1, { limit = 10000 })
	for _, m in ipairs(marks) do
		if m[1] == mark_id then
			return m[2] -- row (0-based)
		end
	end
	return nil
end

local desc_lines = function(desc)
	if not desc or desc == "" then
		return { "<no description>" }
	end
	return vim.split(desc, "\n", { trimempty = true })
end

M.toggle_details_on_todo = function()
	local row = api.nvim_win_get_cursor(state.floats.body.win)[1] - 1
	local id = extmark_on_row(row)
	local meta = items_with_details and items_with_details[id]
	if not meta then
		return
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = state.floats.body.buf })

	if meta.shown then
		local end_row = extmark_row_by_id(meta.end_mark)
		if end_row then
			api.nvim_buf_set_lines(state.floats.body.buf, row + 1, end_row + 1, false, {})
			pcall(api.nvim_buf_del_extmark, state.floats.body.buf, M.namespace, meta.end_mark)
		end
		meta.shown = false
		meta.end_mark = nil
	else
		local item = state.todos[meta.idx]
		local item_desc = desc_lines(item.description)

		api.nvim_buf_set_lines(state.floats.body.buf, row + 1, row + 1, false, item_desc)
		for i = 1, #item_desc do
			local r = row + i
			vim.hl.range(state.floats.body.buf, M.namespace_hl, "TodoDescription", { r, 0 }, { r, -1 })
		end
		local end_mark = api.nvim_buf_set_extmark(state.floats.body.buf, M.namespace, row + 1, 0, {})
		meta.end_mark = end_mark
		meta.shown = true
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = state.floats.body.buf })
end

M.render_todos = function()
	items_with_details = {}
	local windows_config = get_window_config()

	state.floats.header = create_window(windows_config.header)
	state.floats.body = create_window(windows_config.body, true)

	local title_text = "TODO List"

	local padding = string.rep(" ", (windows_config.header.width - #title_text) / 2)
	local title = padding .. title_text

	local lines = {}
	for _, t in ipairs(state.todos) do
		lines[#lines + 1] = title_line(t)
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = state.floats.body.buf })

	vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
	vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, lines)

	for i, line in ipairs(lines) do
		local mark_id = api.nvim_buf_set_extmark(state.floats.body.buf, M.namespace, i - 1, 0, {})
		items_with_details[mark_id] = {
			idx = i,
			text = utils.strip(line),
			shown = false,
			end_mark = nil,
		}
		if is_done_task(line) then
			vim.hl.range(state.floats.body.buf, M.namespace_hl, "TodoDone", { i - 1, 0 }, { i - 1, -1 })
		end
	end

	foreach_float(function(_, float)
		vim.api.nvim_set_option_value("modifiable", false, { buf = float.buf })
		vim.api.nvim_set_option_value("buftype", "nofile", { buf = float.buf })
	end)

	utils.set_keymap("n", "q", M.close_todos_window)
	utils.set_keymap("n", config.options.keymaps.add_todo, actions.new_todo)
	utils.set_keymap("n", config.options.keymaps.delete_todo, actions.delete_todo)

	vim.keymap.set("n", config.options.keymaps.toggle_details, M.toggle_details_on_todo)

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = state.floats.body.buf,
		callback = function()
			foreach_float(function(_, float)
				pcall(vim.api.nvim_win_close, float.win, true)
			end)
			items_with_details = nil
			api.nvim_buf_clear_namespace(state.floats.body.buf, M.namespace, 0, -1)
		end,
	})
end

M.close_todos_window = function()
	if M.is_todos_window_open() then
		api.nvim_win_close(state.floats.body.win, true)

		state.floats.body.buf = nil
		state.floats.body.win = nil
		state.floats.header.buf = nil
		state.floats.header.win = nil
	end
end

M.is_todos_window_open = function()
	if state.floats.body ~= nil and state.floats.body.win ~= nil and api.nvim_win_is_valid(state.floats.body.win) then
		return true
	end

	return false
end

M.toggle_todos = function()
	if M.is_todos_window_open() then
		M.close_todos_window()
	else
		M.render_todos()
	end
end

return M
