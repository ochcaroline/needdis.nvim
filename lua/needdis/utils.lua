local M = {}

local state = require("needdis.state")

M.strip = function(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

M.set_keymap = function(mode, key, callback)
	vim.keymap.set(mode, key, callback, {
		buffer = state.floats.body.buf,
	})
end

return M
