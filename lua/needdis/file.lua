local M = {}

local config = require("needdis.config")
local state = require("needdis.state")

function M.save_todos()
	local save_path = config.options.save_path
	local file = io.open(save_path, "w")

	if file then
		file:write(vim.fn.json_encode(state.todos))
		file:close()
	end
end

---@param file_path string
function M.ensure_file(file_path)
	local dir = vim.fn.fnamemodify(file_path, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	if vim.fn.filereadable(file_path) == 0 then
		local file = io.open(file_path, "w")
		if file then
			file:close()
		end
	end
end

function M.load_todos()
	local save_path = config.options.save_path
	M.ensure_file(save_path)

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
