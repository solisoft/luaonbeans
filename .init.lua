package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";models/?.lua"
require "utilities"

ENV = {}
for _, var in pairs(unix.environ()) do
	var = string.split(var, "=")
	ENV[var[1]] = var[2]
end

beans_env = ENV['BEANS_ENV'] or "development"

-- ArangoDB connection
db_config = DecodeJson(Slurp("config/database.json"))
adb = require "arango"
print(beans_env)
print(EncodeJson(db_config))
assert(adb.Auth(db_config[beans_env]) ~= null)
adb.UpdateCacheConfiguration({ mode = "on" })

function OnHttpRequest()
	params = GetParams()

	adb.RefreshToken(db_config[beans_env]) -- reconnect to arangoDB if needed

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
