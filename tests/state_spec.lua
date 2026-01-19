local state = require("needdis.state")
local eq = assert.are.same

local needdis = require("needdis")

describe("state", function()
	local temp_files = {}

	after_each(function()
		for _, file_path in ipairs(temp_files) do
			if vim.fn.filereadable(file_path) == 1 then
				os.remove(file_path)
			end
		end
		temp_files = {}
	end)

	local function create_temp_json(content)
		local temp_path = vim.fn.tempname() .. ".json"
		table.insert(temp_files, temp_path)

		local file = io.open(temp_path, "w")
		if file then
			file:write(content or "{}")
			file:close()
		end
		return temp_path
	end

	it("empty state on open with a new file", function()
		local temp_json = create_temp_json()
		needdis.setup({ save_path = temp_json })

		eq(0, #state.todos)
	end)

	it("loads existing todos from file", function()
		local test_todos = vim.fn.json_encode({
			{ title = "Test todo", completed = false, description = "Test description" },
		})
		local temp_json = create_temp_json(test_todos)

		needdis.setup({ save_path = temp_json })

		eq(1, #state.todos)
		eq("Test todo", state.todos[1].title)
		eq(false, state.todos[1].completed)
		eq("Test description", state.todos[1].description)
	end)

	it("creates empty todos array for empty file", function()
		local temp_json = create_temp_json("")
		needdis.setup({ save_path = temp_json })

		eq(0, #state.todos)
	end)
end)
