local config = require("needdis.config")
local eq = assert.are.same

describe("config", function()
	it("create_default_config", function()
		config.setup()
		eq(config.options.icons.done, "✓")
		eq(config.options.keymaps.toggle_details, "<CR>")
	end)
	it("set_save_path", function()
		local path = "/tmp/needdis.json"
		config.setup({ save_path = path })
		eq(config.options.save_path, path)
	end)
end)
