local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJSON({ hello = "world" })
	end,
}

return HandleController(app)
