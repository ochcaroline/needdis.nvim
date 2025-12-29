local config = require("needdis.config")
local eq = assert.are.same

describe("config", function()
	it("create default config", function()
		config.setup()
		eq(config.options.icons.done, "✓")
		eq(config.options.keymaps.toggle_details, "<CR>")
	end)
	it("set save path", function()
		local path = "/tmp/needdis.json"
		config.setup({ save_path = path })
		eq(config.options.save_path, path)
	end)
	it("custom keymap set", function()
		local custom_keymap = "<leader>xdd"
		config.setup({ keymaps = { toggle_window = custom_keymap } })
		eq(config.options.keymaps.toggle_window, custom_keymap)
	end)
end)
