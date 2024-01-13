package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";models/?.lua"
require "utilities"

beans_env = unix.environ()['BEANS_ENV'] or "development"

-- ArangoDB connection
local db_config = DecodeJson(LoadAsset("config/database.json"))
adb = require "arango"
assert(adb.Auth(db_config[beans_env]) ~= null)
adb.UpdateCacheConfiguration({ mode = "on" })

function OnHttpRequest()
	params = GetParams()

	adb.RefreshToken(db_config) -- reconnect to arangoDB if needed

	-- Routes
	---- Basic CRUD
	-- Resource("posts")
	---- Nested CRUD
	-- Resource("comments", { root = "/posts/:post_id", post_id = "([0-9]+)" })
	---- Custom Ruute
	-- CustomRoute("GET", "/posts/:post_id/offline", {
	-- 	post_id = "([0-9]+)", controller = "posts", action = "offline"
	-- })
	---- define root route
	if GetPath() == "/" then
		params.action = "index"
		RoutePath("/controllers/welcome_controller.lua")
	end

	if params.action == null then Route() end
end
