local M = {}

local state = require("needdis.state")
local config = require("needdis.config")

local task_pattern = "[%s+✓+]"
local task_done_pattern = "✓+%s+"

---@param title string
M.is_task = function(title)
	return title:match(task_pattern)
end

---@param str string
M.strip = function(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

---@param mode string|string[]
---@param key string
---@param callback string|function
M.set_keymap = function(mode, key, callback)
	vim.keymap.set(mode, key, callback, {
		buffer = state.floats.body.buf,
	})
end

---@param line string
---@return boolean
M.is_done_task = function(line)
	return line:match(task_done_pattern)
end

---@param line string
---@return string
M.get_title_from_line = function(line)
	return M.strip(line:gsub(config.options.icons.done, ""))
end
return M
