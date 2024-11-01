local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJson({ hello = "world" })
	end,
}

if BeansEnv == "development" then
	return app[Params.action]()
else
	return app
end
