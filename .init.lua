package.path = package.path .. ";.lua/?.lua"
package.path = package.path .. ";app/controllers/?.lua;/zip/app/controllers/?.lua"
package.path = package.path .. ";app/models/?.lua;/zip/app/models/?.lua"
package.path = package.path .. ";app/cronjobs/?.lua;/zip/app/cronjobs/?.lua"
package.path = package.path .. ";config/?.lua;/zip/config/?.lua"

-- OTP = require("otp") -- OTP functions
require("utilities")
require("routes")

local I18nClass = require("i18n")
I18n = I18nClass.new("en")

ProgramMaxPayloadSize(10485760) -- 10 MB

-- DB connection
--local db_config = DecodeJson(LoadAsset("config/database.json"))
--InitDB(db_config)

Views = {}
IsApi = false -- set it to true to return json for 404 errors

-- LastModifiedAt is used to cache the last modified time of the assets
-- so that we can use it to send the correct last modified time to the client
-- and avoid sending the whole file to the client
LastModifiedAt = {}

function OnServerStart()
	LoadPublicAssetsRecursively("public")
	if BeansEnv == "production" then
		LoadViewsRecursively("app/views")
	end
end

function OnServerReload() end

function OnServerHeartbeat()
	LoadCronsJobs()
end

function OnWorkerStart()
	-- Uncomment code if you use SQLite
	-- HandleSqliteFork(db_config) -- you can remove it if you do not use SQLite
end

-- OnError hook
function OnError(status, message, details)
	-- Define the error for an API
	-- WriteJSON({ status = status, message = message })

	-- Define the error page via a page with a layout
	Params.status = status
	Params.message = message
	Params.details = details
	Params.env = BeansEnv

	SetStatus(status)
	Page("errors/index", "app")
end

-- OnHttpRequest hook
function OnHttpRequest()
	-- local redis = require "db.redis"
	-- Redis = redis.connect()

	Params = GetParams()
	PrepareMultiPartParams() -- if you handle file uploads

	SetDevice() -- comment if you do not need this feature

	-- Uncomment code if you use ArangoDB
	-- if Adb then
	--  Adb.primary:RefreshToken() -- reconnect to arangoDB if needed
	-- end

	-- Uncomment code if you use surrealdb
	-- if (db_config ~= nil and db_config["engine"] == "surrealdb") then
	--  Surreal.refresh_token(db_config[BeansEnv]) -- reconnect to surrealdb if needed
	-- end

	DefineRoute(GetPath(), GetMethod())

	HandleRequest()
	-- Uncomment if you use redis
	-- unix.close(Redis.network.socket)
end

function SetDevice()
	local user_agent = GetHeader("User-Agent")
	Params.request = { variant = "" }
	local preg = assert(re.compile("iPhone"))
	if preg:search(user_agent) then
		Params.request.variant = "iphone"
	end
end
