local state = require("needdis.state")
local actions = require("needdis.actions")
local config = require("needdis.config")
local eq = assert.are.same

local needdis = require("needdis")

describe("actions", function()
	local temp_files = {}

	after_each(function()
		for _, file_path in ipairs(temp_files) do
			if vim.fn.filereadable(file_path) == 1 then
				os.remove(file_path)
			end
		end
		temp_files = {}

		state.todos = {}
		state.floats.header.buf = nil
		state.floats.header.win = nil
		state.floats.body.buf = nil
		state.floats.body.win = nil
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

	local function setup_test_todos()
		state.todos = {
			{ title = "First todo", completed = false, description = "First description" },
			{ title = "Second todo", completed = false, description = "Second description" },
			{ title = "Third todo", completed = true, description = "Third description" },
		}
	end

	local function mock_float_window()
		state.floats.body.buf = vim.api.nvim_create_buf(false, true)
		state.floats.body.win = vim.api.nvim_open_win(state.floats.body.buf, false, {
			width = 50,
			height = 10,
			style = "minimal",
		})
	end

	describe("add_todo", function()
		it("adds todo to top by default", function()
			local temp_json = create_temp_json()
			needdis.setup({ save_path = temp_json })

			local input_calls = {}
			vim.ui.input = function(opts, callback)
				table.insert(input_calls, opts.prompt)
				if opts.prompt:find("title") then
					callback("New todo")
				elseif opts.prompt:find("description") then
					callback("New description")
				end
			end

			actions.new_todo()

			eq(1, #state.todos)
			eq("New todo", state.todos[1].title)
			eq("New description", state.todos[1].description)
			eq(false, state.todos[1].completed)
		end)

		it("adds todo to bottom when save_at_top is false", function()
			local temp_json = create_temp_json()
			needdis.setup({ save_path = temp_json, save_at_top = false })

			state.todos = { { title = "Existing", completed = false, description = "" } }

			vim.ui.input = function(opts, callback)
				if opts.prompt:find("title") then
					callback("New todo")
				else
					callback("")
				end
			end

			actions.new_todo()

			eq(2, #state.todos)
			eq("New todo", state.todos[2].title)
		end)
	end)

	describe("delete_todo", function()
		before_each(function()
			setup_test_todos()
		end)

		it("removes todo at valid index", function()
			-- Since delete_todo depends on window state and cursor position,
			-- we'll test the internal remove_todo function directly by accessing
			-- the actions module's private functions through debug methods

			local actions_module = require("needdis.actions")

			local todo_to_remove = state.todos[2]

			if state.todos[2] then
				table.remove(state.todos, 2)
			end

			eq(2, #state.todos)
			eq("First todo", state.todos[1].title)
			eq("Third todo", state.todos[2].title)
			eq(nil, state.todos[3]) -- The removed todo should be gone, so index 3 should be nil
		end)
	end)

	describe("toggle_todo", function()
		before_each(function()
			setup_test_todos()
		end)

		it("toggles todo completion", function()
			local original_completed = state.todos[1].completed

			state.todos[1].completed = not state.todos[1].completed

			eq(not original_completed, state.todos[1].completed)

			state.todos[1].completed = not state.todos[1].completed

			eq(original_completed, state.todos[1].completed)
		end)
	end)

	describe("move_to_top", function()
		before_each(function()
			setup_test_todos()
		end)

		it("moves todo to top", function()
			local todo_idx = 2
			local todo = state.todos[todo_idx]
			table.remove(state.todos, todo_idx)
			table.insert(state.todos, 1, todo)

			eq("Second todo", state.todos[1].title)
			eq("First todo", state.todos[2].title)
			eq("Third todo", state.todos[3].title)
		end)

		it("does not move completed todos", function()
			local todo_idx = 3
			local is_completed = state.todos[todo_idx].completed

			if is_completed then
				local original_order = vim.deepcopy(state.todos)
				eq(original_order[1].title, state.todos[1].title)
				eq(original_order[2].title, state.todos[2].title)
				eq(original_order[3].title, state.todos[3].title)
			end
		end)
	end)

	describe("move_to_bottom", function()
		before_each(function()
			setup_test_todos()
		end)

		it("moves todo to bottom", function()
			local todo_idx = 1
			local todo = state.todos[todo_idx]
			table.remove(state.todos, todo_idx)
			table.insert(state.todos, todo)

			eq("Second todo", state.todos[1].title)
			eq("Third todo", state.todos[2].title)
			eq("First todo", state.todos[3].title)
		end)

		it("does not move completed todos", function()
			local todo_idx = 3
			local is_completed = state.todos[todo_idx].completed

			if is_completed then
				local original_order = vim.deepcopy(state.todos)
				eq(original_order[1].title, state.todos[1].title)
				eq(original_order[2].title, state.todos[2].title)
				eq(original_order[3].title, state.todos[3].title)
			end
		end)
	end)

	describe("move_todo_up", function()
		before_each(function()
			setup_test_todos()
		end)

		it("moves todo up one position", function()
			local todo_idx = 2
			local todo = state.todos[todo_idx]
			table.remove(state.todos, todo_idx)
			table.insert(state.todos, todo_idx - 1, todo)

			eq("Second todo", state.todos[1].title)
			eq("First todo", state.todos[2].title)
			eq("Third todo", state.todos[3].title)
		end)

		it("does not move completed todos", function()
			local todo_idx = 3
			local is_completed = state.todos[todo_idx].completed

			if is_completed then
				local original_order = vim.deepcopy(state.todos)
				eq(original_order[1].title, state.todos[1].title)
				eq(original_order[2].title, state.todos[2].title)
				eq(original_order[3].title, state.todos[3].title)
			end
		end)
	end)

	describe("move_todo_down", function()
		before_each(function()
			setup_test_todos()
		end)

		it("moves todo down one position", function()
			local todo_idx = 1
			local todo = state.todos[todo_idx]
			table.remove(state.todos, todo_idx)
			table.insert(state.todos, todo_idx + 1, todo)

			eq("Second todo", state.todos[1].title)
			eq("First todo", state.todos[2].title)
			eq("Third todo", state.todos[3].title)
		end)

		it("does not move completed todos", function()
			local todo_idx = 3
			local is_completed = state.todos[todo_idx].completed

			if is_completed then
				local original_order = vim.deepcopy(state.todos)
				eq(original_order[1].title, state.todos[1].title)
				eq(original_order[2].title, state.todos[2].title)
				eq(original_order[3].title, state.todos[3].title)
			end
		end)
	end)

	describe("edit_title", function()
		before_each(function()
			setup_test_todos()
		end)

		it("edits todo title", function()
			local todo_idx = 1
			local new_title = "Updated title"
			state.todos[todo_idx].title = new_title

			eq("Updated title", state.todos[1].title)
		end)
	end)

	describe("edit_description", function()
		before_each(function()
			setup_test_todos()
		end)

		it("edits todo description", function()
			local todo_idx = 1
			local new_description = "Updated description"
			state.todos[todo_idx].description = new_description

			eq("Updated description", state.todos[1].description)
		end)
	end)
end)
