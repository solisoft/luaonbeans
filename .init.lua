package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";models/?.lua;/zip/models/?.lua"
package.path = package.path .. ";config/?.lua;/zip/config/?.lua"

require("utilities")

Routes = require("routes")

-- ArangoDB connection
local db_config = DecodeJson(LoadAsset("config/database.json"))
if (db_config["engine"] == "arangodb") then
  Adb = require("arango")
  Adb.Auth(db_config[BeansEnv])
  Adb.UpdateCacheConfiguration({ mode = "on" })
elseif (db_config["engine"] == "sqlite") then
  local sqlite3 = require 'lsqlite3'
  local sqlite = sqlite3.open(db_config[BeansEnv]["db_name"] .. '.sqlite3')
  sqlite:busy_timeout(1000)
  sqlite:exec [[PRAGMA journal_mode=WAL]]
  sqlite:exec [[PRAGMA synchronous=NORMAL]]
  sqlite:exec [[
    CREATE TABLE IF NOT EXISTS "migrations"
    (
      id integer PRIMARY KEY,
      filename VARCHAR
    );

    CREATE UNIQUE INDEX idx_migrations_filename ON migrations (filename);
  ]]
end

function OnWorkerStart()
  if db_config["engine"] == "sqlite" then
    Sqlite3 = require 'lsqlite3'
    Sqlite = Sqlite3.open('delupay-shop.sqlite3')
    Sqlite:busy_timeout(1000)
    Sqlite:exec [[PRAGMA journal_mode=WAL]]
    Sqlite:exec [[PRAGMA synchronous=NORMAL]]
  end
end

-- OnError hook
function OnError(status, message)
  -- Define the error for an API
  -- WriteJSON({ status = status, message = message })

  -- Define the error page via a page with a layout
  Params.status = status
  Params.message = message
  Page("errors/index", "app")
end

-- OnHttpRequest hook
function OnHttpRequest()
  Params = GetParams()
  PrepareMultiPartParams() -- if you handle file uploads
  GenerateCSRFToken()

  if (db_config["engine"] == "arangodb") then
    Adb.RefreshToken(db_config[BeansEnv]) -- reconnect to arangoDB if needed
  end

  Routes()
end
