local M = {}

local config = require("needdis.config")
local file = require("needdis.file")
local render = require("needdis.render")

M.setup = function(opts)
	config.setup(opts)
	file.load_todos()

	vim.keymap.set("n", "<leader>at", render.toggle_todos)
end

return M
