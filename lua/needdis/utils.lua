local M = {}

local state = require("needdis.state")

local task_pattern = "[%s+✓+]"
local task_done_pattern = "✓+%s+"

M.is_task = function(title)
	return title:match(task_pattern)
end

M.strip = function(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

M.set_keymap = function(mode, key, callback)
	vim.keymap.set(mode, key, callback, {
		buffer = state.floats.body.buf,
	})
end

M.is_done_task = function(line)
	return line:match(task_done_pattern)
end

return M
