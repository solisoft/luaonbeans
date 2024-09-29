local app = {

	index = function()
		Page("welcome/index", "app")
	end,
}

return app[Params.action]()
