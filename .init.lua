package.path = package.path .. ";.lua/?.lua"
require "utilities"

-- ArangoDB connection
local db_config = DecodeJson(LoadAsset("config/database.json"))
adb = require "arango"
assert(adb.Auth(db_config) ~= null)
adb.UpdateCacheConfiguration({ mode = "on" })

function OnHttpRequest()
	params = GetParams()

	adb.RefreshToken(db_config) -- reconnect to arangoDB if needed

	-- routes
	Resource('posts')
	NestedResource('comments', '/posts/:post_id', {
		post_id = "([0-9]+)"
	})

	-- define root route
	if GetPath() == '/' then
		params['action'] = 'index'
		RoutePath("/controllers/welcome_controller.lua")
	end

	if params['action'] == null then Route() end
end
