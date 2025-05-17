local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJSON({ "demo" => true })
	end,
}

return HandleController(app)
