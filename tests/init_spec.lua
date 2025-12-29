local needdis = require("needdis")
local state = require("needdis.state")
local config = require("needdis.config")
local eq = assert.are.same

local save_path = "/tmp/needdis.json"

describe("init", function()
	it("properly initialised", function()
		needdis.setup({ save_path = save_path })
		eq(config.options.save_path, save_path)
	end)

	it("list empty after init", function()
		needdis.setup({ save_path = save_path })
		eq(#state.todos, 0)
	end)
end)
