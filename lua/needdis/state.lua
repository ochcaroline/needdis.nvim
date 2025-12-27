---@class FloatWindow
---@field buf number|nil
---@field win number|nil

---@class Floats
---@field header FloatWindow
---@field body FloatWindow

---@class Todo
---@field title string
---@field completed boolean
---@field description string

---@class State
---@field floats Floats
---@field todos Todo[]

local M = {
	floats = {
		header = {
			buf = nil,
			win = nil,
		},
		body = {
			buf = nil,
			win = nil,
		},
	},
	todos = {},
}

return M
