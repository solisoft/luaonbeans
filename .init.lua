package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";models/?.lua"
require "utilities"

ENV = {}
for _, var in pairs(unix.environ()) do
  var = string.split(var, "=")
  ENV[var[1]] = var[2]
end

BeansEnv = ENV['BEANS_ENV'] or "development"

-- ArangoDB connection
local db_config = DecodeJson(LoadAsset("config/database.json"))
Adb = require "arango"
assert(Adb.Auth(db_config[BeansEnv]) ~= nil)
Adb.UpdateCacheConfiguration({ mode = "on" })

function OnHttpRequest()
  Params = GetParams()
  PrepareMultiPartParams()

  GenerateCSRFToken()

  Adb.RefreshToken(db_config[BeansEnv]) -- reconnect to arangoDB if needed

  -- Routes
  ---- Basic CRUD
  Resource("posts")
  ---- Nested CRUD
  -- Resource("comments", { root = "/posts/:post_id", post_id = "([0-9]+)" })
  ---- Custom Ruute
  -- CustomRoute("GET", "/posts/:post_id/offline", {
  -- 	post_id = "([0-9]+)", controller = "posts", action = "offline"
  -- })
  ---- define root route
  if GetPath() == "/" then
    Params.action = "index"
    RoutePath("/controllers/welcome_controller.lua")
  end

  -- if GetPath() == "/upload" and GetMethod() == "POST" then
  -- 	Params.action = "create"
  -- 		RoutePath("/controllers/welcome_controller.lua")
  -- end

  if Params.action == nil then Route() end
end
