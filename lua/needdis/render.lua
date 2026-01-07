local M = {}

local api = vim.api

local state = require("needdis.state")
local actions = require("needdis.actions")
local utils = require("needdis.utils")
local config = require("needdis.config")

M.namespace = api.nvim_create_namespace("needdis_ns")
M.namespace_hl = api.nvim_create_namespace("needdis_hl")
M.current_context = "global"

local hl_name_done = "TodoDone"
local hl_name_description = "TodoDescription"
api.nvim_set_hl(0, hl_name_done, { fg = "#696969", strikethrough = true })
api.nvim_set_hl(0, hl_name_description, { fg = "#656565", italic = true })

local items_with_details = {}

---@return { header: vim.api.keyset.win_config, body: vim.api.keyset.win_config }
local function get_window_config()
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

---@param cfg vim.api.keyset.win_config
---@param enter boolean?
---@return { buf: integer, win: integer }
local function create_window(cfg, enter)
	if enter == nil then
		enter = false
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(bufnr, enter or false, cfg)

	return { buf = bufnr, win = win }
end

---@param cb function
local function foreach_float(cb)
	for name, float in pairs(state.floats) do
		cb(name, float)
	end
end

---@param item Todo
---@return string
local function title_line(item)
	return string.format("%s %s", item.completed and config.options.icons.done or " ", item.title)
end

---@param row integer
---@return integer|nil
local function extmark_on_row(row)
	local marks = api.nvim_buf_get_extmarks(state.floats.body.buf, M.namespace, { row, 0 }, { row, 1 }, { limit = 1 })
	if marks and marks[1] then
		return marks[1][1]
	end
	return nil
end

---@param mark_id integer
---@return integer|nil
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

---@param desc string
---@return string[]
local function desc_lines(desc)
	if not desc or desc == "" then
		return { string.format("   %s", config.options.messages.no_description) }
	end
	local items = vim.split(desc, "\n", { trimempty = true })
	for i, item in ipairs(items) do
		items[i] = string.format("   %s", item)
	end

	return items
end

function M.toggle_details_on_todo()
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
		if item ~= nil then
			local item_desc = desc_lines(item.description)

			api.nvim_buf_set_lines(state.floats.body.buf, row + 1, row + 1, false, item_desc)
			for i = 1, #item_desc do
				local r = row + i
				vim.hl.range(state.floats.body.buf, M.namespace_hl, hl_name_description, { r, 0 }, { r, -1 })
			end
			local end_mark = api.nvim_buf_set_extmark(state.floats.body.buf, M.namespace, row + 1, 0, {})
			meta.end_mark = end_mark
			meta.shown = true
		end
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = state.floats.body.buf })
end

---@param existing { buf: integer, win: integer }
---@param cfg vim.api.keyset.win_config
---@param enter boolean?
---@return { buf: integer, win: integer }
local function ensure_window(existing, cfg, enter)
	if existing and existing.win and vim.api.nvim_win_is_valid(existing.win) then
		return existing
	else
		return create_window(cfg, enter)
	end
end

local function setup_keymaps()
	utils.set_keymap("n", config.options.keymaps.add_todo, function()
		actions.new_todo()
		M.render_todos()
	end)
	utils.set_keymap("n", config.options.keymaps.delete_todo, function()
		actions.delete_todo()
		M.render_todos()
	end)
	utils.set_keymap("n", config.options.keymaps.toggle_completed, function()
		actions.action_after_set_cursor(actions.toggle_todo)
	end)
	utils.set_keymap("n", config.options.keymaps.toggle_details, M.toggle_details_on_todo)
	utils.set_keymap("n", config.options.keymaps.edit_title, function()
		actions.action_after_set_cursor(actions.edit_title)
	end)
	utils.set_keymap("n", config.options.keymaps.edit_description, function()
		actions.action_after_set_cursor(actions.edit_description)
	end)
	utils.set_keymap("n", config.options.keymaps.move_to_top, actions.move_to_top)
	utils.set_keymap("n", config.options.keymaps.move_to_bottom, actions.move_to_bottom)

	vim.keymap.set("n", config.options.keymaps.toggle_details, M.toggle_details_on_todo)
end

function M.render_todos()
	items_with_details = {}
	local windows_config = get_window_config()

	state.floats.header = ensure_window(state.floats.header, windows_config.header)
	state.floats.body = ensure_window(state.floats.body, windows_config.body, true)

	foreach_float(function(_, float)
		vim.api.nvim_set_option_value("modifiable", true, { buf = float.buf })
	end)

	local title_text = config.options.messages.title
	local padding = string.rep(" ", (windows_config.header.width - #title_text) / 2)
	local title = padding .. title_text

	local incomplete, complete = {}, {}
	for idx, t in ipairs(state.todos) do
		if t.completed then
			table.insert(complete, { item = t, idx = idx })
		else
			table.insert(incomplete, { item = t, idx = idx })
		end
	end

	local lines = {}
	table.insert(lines, config.options.messages.todo_status_header)
	if #incomplete > 0 then
		for _, t in ipairs(incomplete) do
			table.insert(lines, title_line(t.item))
		end
	else
		table.insert(lines, "no items")
	end

	table.insert(lines, "")
	table.insert(lines, "")
	table.insert(lines, config.options.messages.completed_status_header)

	if #complete > 0 then
		for _, t in ipairs(complete) do
			table.insert(lines, title_line(t.item))
		end
	else
		table.insert(lines, "no items")
	end

	vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
	vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, lines)

	local line_to_todo_idx = {}
	local current_line = 1

	current_line = current_line + 1 -- "TODO:" header
	for _, t in ipairs(incomplete) do
		line_to_todo_idx[current_line] = t.idx
		current_line = current_line + 1
	end

	current_line = current_line + 2 -- line split
	current_line = current_line + 1 -- "Completed" header
	for _, t in ipairs(complete) do
		line_to_todo_idx[current_line] = t.idx
		current_line = current_line + 1
	end

	for i, line in ipairs(lines) do
		if utils.is_task(line) then
			local mark_id = api.nvim_buf_set_extmark(state.floats.body.buf, M.namespace, i - 1, 0, {})
			local todo_idx = line_to_todo_idx[i]
			items_with_details[mark_id] = {
				idx = todo_idx,
				text = utils.strip(line),
				shown = false,
				end_mark = nil,
			}
			if utils.is_done_task(line) then
				vim.hl.range(state.floats.body.buf, M.namespace_hl, hl_name_done, { i - 1, 0 }, { i - 1, -1 })
			end
		end

		if utils.strip(line) == "no items" then
			vim.hl.range(state.floats.body.buf, M.namespace_hl, hl_name_description, { i - 1, 0 }, { i - 1, -1 })
		end
	end

	foreach_float(function(_, float)
		vim.api.nvim_set_option_value("modifiable", false, { buf = float.buf })
		vim.api.nvim_set_option_value("buftype", "nofile", { buf = float.buf })
	end)

	setup_keymaps()

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = state.floats.body.buf,
		callback = function()
			foreach_float(function(_, float)
				pcall(vim.api.nvim_win_close, float.win, true)
			end)
		end,
	})
end

function M.close_todos_window()
	if state.floats.body and state.floats.body.win and api.nvim_win_is_valid(state.floats.body.win) then
		api.nvim_win_close(state.floats.body.win, true)
	end
	if state.floats.header and state.floats.header.win and api.nvim_win_is_valid(state.floats.header.win) then
		api.nvim_win_close(state.floats.header.win, true)
	end
	state.floats.body.buf = nil
	state.floats.body.win = nil
	state.floats.header.buf = nil
	state.floats.header.win = nil
end

---@return boolean
function M.is_todos_window_open()
	if state.floats.body ~= nil and state.floats.body.win ~= nil and api.nvim_win_is_valid(state.floats.body.win) then
		return true
	end

	return false
end

function M.toggle_todos()
	if M.is_todos_window_open() then
		M.close_todos_window()
	else
		M.render_todos()
	end
end

---@return table
function M.get_items_with_details()
	return items_with_details
end

return M
