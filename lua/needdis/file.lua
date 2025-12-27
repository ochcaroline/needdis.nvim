local M = {}

local config = require("needdis.config")
local state = require("needdis.state")

M.save_todos = function()
	local save_path = config.options.save_path
	local file = io.open(save_path, "w")

	if file then
		file:write(vim.fn.json_encode(state.todos))
		file:close()
	end
end

M.load_todos = function()
	local save_path = config.options.save_path
	local file = io.open(save_path, "r")
	if file then
		local content = file:read("*all")
		file:close()

		if content and content ~= "" then
			state.todos = vim.fn.json_decode(content)
		else
			state.todos = {}
		end
	end
end

return M
