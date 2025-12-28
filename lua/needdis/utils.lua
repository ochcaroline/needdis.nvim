local M = {}

local state = require("needdis.state")
local config = require("needdis.config")

local task_pattern = "[%s+✓+]"
local task_done_pattern = "✓+%s+"

---@param title string
function M.is_task(title)
	return title:match(task_pattern)
end

---@param str string
function M.strip(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

---@param mode string|string[]
---@param key string
---@param callback string|function
function M.set_keymap(mode, key, callback)
	vim.keymap.set(mode, key, callback, {
		buffer = state.floats.body.buf,
	})
end

---@param line string
---@return boolean
function M.is_done_task(line)
	return line:match(task_done_pattern)
end

---@param line string
---@return string
function M.get_title_from_line(line)
	return M.strip(line:gsub(config.options.icons.done, ""))
end

return M
