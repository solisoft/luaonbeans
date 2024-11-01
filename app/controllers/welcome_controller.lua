local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJson({ hello = "world" })
	end,
}

return app
