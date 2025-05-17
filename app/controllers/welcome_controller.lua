local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- local data = Adb.primary:Aql([[
		-- 	FOR c IN customers LIMIT 10 RETURN c
		-- ]]).result
		-- WriteJSON(data)
	end,
}

return HandleController(app)
