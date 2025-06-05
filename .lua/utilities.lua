Unix = require "unix"
Re = require "re"
Etlua = require "etlua"
Multipart = require "multipart"
JWT = require("jwt")

ProgramHeartbeatInterval(1000) -- 1 second
ProgramBrand("LuaOnBeans")

require "utilities.table"
require "utilities.string"
require "utilities.multipart"
require "utilities.csrf"
require "utilities.aqlpages"

HandleCronJob = require("utilities.cronjobs").HandleCronJob

require "luaonbeans"

ENV = {}
for _, var in pairs(unix.environ()) do
	var = string.split(var, "=")
	ENV[var[1]] = var[2]
end

BeansEnv = ENV['BEANS_ENV'] or "development"

local env_file = ".env"
if BeansEnv == "test" then env_file = ".env.test" end

local env_data = LoadAsset(env_file)
if env_data then
	for line in env_data:gmatch("[^\r\n]+") do
		local key, value = line:match("([^=]+)=(.+)")
		if key and value then
			ENV[key:gsub("%s+", "")] = value:gsub("%s+", "")
		end
	end
end

function Logger(message)
	if type(message) == "table" then
		message = EncodeJson(message)
	end
	Log(kLogError, message)
end
