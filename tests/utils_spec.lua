local utils = require("needdis.utils")

local eq = assert.are.equal

describe("needdis.utils", function()
	it("strip trims whitespace", function()
		eq(utils.strip("  hello  "), "hello")
		eq(utils.strip("\thello\t"), "hello")
		eq(utils.strip("hello"), "hello")
	end)
end)
