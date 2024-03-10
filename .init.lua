package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";models/?.lua"
package.path = package.path .. ";?.lua"
require "utilities"

Routes = require "routes"

-- ArangoDB connection

local db_config = DecodeJson(LoadAsset("config/database.json"))
Adb = require "arango"
Adb.Auth(db_config[BeansEnv])
Adb.UpdateCacheConfiguration({ mode = "on" })

function OnError(status, message)
  -- Define the error for an API
  -- WriteJSON({ status = status, message = message })

  -- Define the error page via a page with a layout
  Params.status = status
  Params.message = message
  Page('errors/index', 'app')
end

function OnHttpRequest()
  Params = GetParams()
  PrepareMultiPartParams()              -- if you handle file uploads
  GenerateCSRFToken()
  Adb.RefreshToken(db_config[BeansEnv]) -- reconnect to arangoDB if needed

  Routes()
end
