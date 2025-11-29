Routes = {}
-- DBs
Adb = {}
Crate = {}
PGRest = {}
Rest = {}
Surreal = {}
Blocks = {}

function LoadViewsRecursively(path)
	local dir = unix.opendir(path)
	assert(dir ~= nil, "Error while opening path " .. path)

	while true do
		local file, kind = dir:read()
		if kind == unix.DT_DIR and file ~= "." and file ~= ".." then
			LoadViewsRecursively(path .. "/" .. file)
		end
		if kind == unix.DT_REG then
			if string.match(file, "%.etlua$") then
				Views[path .. "/" .. file] = Etlua.compile(LoadAsset(path .. "/" .. file))
			end
		end

		if file == nil then
			break
		end
	end
	dir:close()
end

function Page(view, layout, bindVarsView, bindVarsLayout)
	local variant = Params.request.variant or ""

	if BeansEnv == "development" then
		local asset = nil
		if variant == "" then
			asset = LoadAsset("app/views/layouts/" .. layout .. "/index.html.etlua")
			Views["app/views/layouts/" .. layout .. "/index.html.etlua"] = Etlua.compile(asset)
		else
			asset = LoadAsset("app/views/layouts/" .. layout .. "/index.html+" .. variant .. ".etlua")
			if asset == nil then
				asset = LoadAsset("app/views/layouts/" .. layout .. "/index.html.etlua")
			end
			Views["app/views/layouts/" .. layout .. "/index.html+" .. variant .. ".etlua"] = Etlua.compile(asset)
		end

		if variant == "" then
			asset = LoadAsset("app/views/" .. view .. ".etlua")
			Views["app/views/" .. view .. ".etlua"] = Etlua.compile(asset)
		else
			asset = LoadAsset("app/views/" .. view .. "+" .. variant .. ".etlua")
			if asset == nil then
				asset = LoadAsset("app/views/" .. view .. ".etlua")
			end
			Views["app/views/" .. view .. "+" .. variant .. ".etlua"] = Etlua.compile(asset)
		end
	end

	compiled_view = Views["app/views/" .. view .. ".etlua"]
	if variant ~= "" then
		compiled_view = Views["app/views/" .. view .. "+" .. variant .. ".etlua"] or compiled_view
	end
	view = compiled_view(bindVarsView or {})

	compiled_layout = Views["app/views/layouts/" .. layout .. "/index.html.etlua"]
	if variant ~= "" then
		compiled_layout = Views["app/views/layouts/" .. layout .. "/index.html+" .. variant .. ".etlua"]
			or compiled_layout
	end
	layout = compiled_layout(bindVarsLayout or {})

	local content
	if view:find("%%") then
		content = layout:gsub("@yield", view:gsub("%%", "%%%%"))
	else
		content = layout:gsub("@yield", view)
	end
	local etag = EncodeBase64(Md5(content))

	if etag == GetHeader("If-None-Match") then
		SetStatus(304)
	else
		SetHeader("Etag", etag)
		Write(content)
	end
end

function Partial(partial, bindVars)
	bindVars = bindVars or {}
	if bindVars.aql then
		local req = Adb.Aql(bindVars.aql, bindVars.bindVars or {})
		bindVars.results = req["result"]
		bindVars.extras = req["extras"]
	end

	if BeansEnv == "development" then
		Views["app/views/partials/" .. partial .. ".html.etlua"] =
			Etlua.compile(LoadAsset("app/views/partials/" .. partial .. ".html.etlua"))
	end

	return Views["app/views/partials/" .. partial .. ".html.etlua"](bindVars)
end

---Helper method ContentFor
---@param tag string name of the content
---@param block function the function to be executed
---@return nil
function ContentFor(tag, block)
	Blocks[tag] = Blocks[tag] or {}
	table.insert(Blocks[tag], block())
end

---Helper method YieldContent
---@param tag string name of the content
---@return string content
function YieldContent(tag)
	return table.concat(Blocks[tag] or {}, "\n")
end

local function assignRoute(method, name, options, value)
	local path = string.split(name, "/")
	Routes[method] = Routes[method] or {}
	local current = Routes[method]
	options["parent"] = options["parent"] or {}

	for i = 1, #options["parent"] do
		local parent = options["parent"][i]

		current[parent] = current[parent] or {}
		current[parent][":var"] = current[parent][":var"] or {}
		if options["type"] == "member" then
			current = current[parent][":var"]
		else
			current = current[parent]
		end
	end

	if #path > 0 then
		for i = 1, #path do
			local v = path[i]
			if v:sub(1, 1) == ":" then
				current[":var"] = {
					[":name"] = v:sub(2),
					[":regex"] = options[v] or "([0-9a-zA-Z_\\-]+)",
				}
				if i == #path then
					current[":var"][""] = value
				end
				current = current[":var"]
			else
				current[v] = current[v] or {}
				if i == #path then
					current[v] = value
				end
				current = current[v]
			end
		end
	else
		current[""] = value
	end
end

function Resource(name, options)
	options = options or {}
	options["parent"] = options["parent"] or {}
	options["only"] = options["only"] or { "index", "show", "new", "create", "edit", "update", "delete" }
	options["type"] = "member"
	local only = options["only"]
	Routes["POST"] = Routes["POST"] or {}
	Routes["PUT"] = Routes["PUT"] or {}
	Routes["DELETE"] = Routes["DELETE"] or {}

	local get = {}
	if table.contains(only, "index") then
		get[""] = name .. "#index"
	end
	if table.contains(only, "new") then
		get["new"] = name .. "#new"
	end
	get[":var"] = {
		[":name"] = options["var_name"] or "id",
		[":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)",
	}
	if table.contains(only, "edit") then
		get[":var"]["edit"] = name .. "#edit"
	end
	if table.contains(only, "show") then
		get[":var"][""] = name .. "#show"
	end
	assignRoute("GET", name, options, get)

	local post = {}
	if table.contains(only, "create") then
		post[""] = name .. "#create"
	end
	post[":var"] = {
		[":name"] = options["var_name"] or "id",
		[":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)",
	}
	assignRoute("POST", name, options, post)

	local put = {}
	if table.contains(only, "update") then
		put[""] = name .. "#update"
	end
	put[":var"] = {
		[":name"] = options["var_name"] or "id",
		[":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)",
	}
	assignRoute("PUT", name, options, put)

	local delete = {}
	delete[":var"] = {
		[":name"] = options["var_name"] or "id",
		[":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)",
	}
	if table.contains(only, "delete") then
		delete[":var"][""] = name .. "#delete"
	end
	assignRoute("DELETE", name, options, delete)
end

function CustomRoute(method, name, endpoint, options)
	options = options or {}

	assignRoute(method, name, options, endpoint)
end

local function tableSplat(input_list)
	local output_table = {}
	for i = 1, #input_list, 2 do
		local key = input_list[i]
		local value = input_list[i + 1]

		-- Convert the value to a number if possible
		local numeric_value = tonumber(value)
		if numeric_value then
			output_table[key] = numeric_value
		else
			output_table[key] = value
		end
	end
	return output_table
end

function DefineRoute(path, method)
	if method == "PATCH" then	method = "PUT" end

	if method == "POST" and Params._method ~= nil then method = Params._method end

	local recognized_route = Routes[method]
	local route_found = false
	local final_route = false

	local last_route_found = nil

	Splat = {}
	if path == "/" then
		recognized_route = recognized_route[""] or recognized_route["@"]
	else
		for _, value in pairs(string.split(path, "/")) do
			if final_route == false then
				if recognized_route[value] or recognized_route[value .. "*"] then
					if recognized_route[value .. "*"] then
						final_route = true
					end
					recognized_route = recognized_route[value] or recognized_route[value .. "*"]
					if recognized_route[""] or recognized_route["@"] then
						last_route_found = recognized_route[""] or recognized_route["@"]
					end
					route_found = true
				else
					route_found = false
					if recognized_route[":var"] then
						recognized_route = recognized_route[":var"]
						if recognized_route[""] or recognized_route["@"] then
							last_route_found = recognized_route[""] or recognized_route["@"]
						end
						local parser = Re.compile(recognized_route[":regex"])
						local matcher = { parser:search(value) }
						for i, match in ipairs(matcher) do
							if i > 1 then
								route_found = true
								Params[recognized_route[":name"]] = match
							end
						end
					end
				end
			else
				table.append(Splat, { value })
			end
		end

		if type(recognized_route) == "table" and route_found then
			recognized_route = recognized_route[""] or recognized_route["@"]
		else
			if route_found == false then
				recognized_route = nil
			end
		end

		Splat = tableSplat(Splat)
	end

	if recognized_route == nil and last_route_found ~= nil then
		recognized_route = last_route_found
	end

	if recognized_route ~= nil then
		recognized_route = string.split(recognized_route, "#")
		Params = table.merge(Params, { controller = recognized_route[1], action = recognized_route[2] })
	end
end

local handle_404_error = function()
	SetStatus(404)
	if IsApi then
		WriteJSON({ status = 404, message = "Not Found" })
	else
		Page("404", "app")
	end
end

function HandleRequest()
	if Params.action == nil then
		local path = GetPath()

		if GetPath() == "/" then
			local default_routes = {
				["GET"] = "/index",
				["POST"] = "/create",
				["PUT"] = "/update",
				["PATCH"] = "/update",
				["DELETE"] = "/delete",
			}
			path = default_routes[GetMethod()]
		end

		local aql_page = nil
		if not string.match(path, "%.") then -- check only if there is no extension
			aql_page = LoadAsset("aqlpages/" .. path .. ".aql")
		end
		if aql_page then
			HandleAqlPage(aql_page)
		else
			if RoutePath("/public" .. path) == false then
				handle_404_error()
			end
		end
	else
		if BeansEnv == "production" then
			local ok, err = pcall(function()
				local controller = require(Params.controller .. "_controller")
				controller[Params.action]()
			end)
			if not ok then
				assert(false, err)
				return
			end
		end
		RoutePath("/app/controllers/" .. Params.controller .. "_controller.lua")
	end
end

function HandleController(controller)
	return BeansEnv == "development" and controller[Params.action]() or controller
end

function GetBodyParams()
	local body_Params = {}
	for _, data in pairs(Params) do
		if type(data) == "table" and #data > 1 then
			body_Params[data[1]] = data[2]
		end
	end

	Params = table.merge(Params, body_Params)
	Params = table.merge(Params, DecodeJson(GetBody()) or {})
	return body_Params
end

function RedirectTo(path)
	status = status or 302
	SetStatus(status)
	SetHeader("Location", path)
end

function WriteJSON(object)
	SetHeader("Content-Type", "application/json; charset=utf-8")
	local json = EncodeJson(object)
	assert(json ~= nil, "Object is not serializable")

	local etag = EncodeBase64(Md5(json))

	if etag == GetHeader("If-None-Match") then
		SetStatus(304)
	else
		SetHeader("Etag", etag)
		Write(json)
	end
end

function InitDB(db_config)
	for _, config in pairs(db_config[BeansEnv]) do
		if config.engine == "crate" then
			local _Crate = require("db.crate")
			Crate[config.name] = _Crate.new(config)
		elseif config.engine == "postgrest" then
			local _PGRest = require("db.postgrest")
			PGRest[config.name] = _PGRest.new(config)
		elseif config.engine == "arangodb" then
			local _Adb = require("db.arangodb")
			local adb_driver = _Adb.new(config)
			adb_driver:UpdateCacheConfiguration({ mode = "on" })
			Adb[config.name] = adb_driver
		elseif config.engine == "db2rest" then
			local _Rest = require("db.db2rest")
			Rest[config.name] = _Rest.new(config)
		elseif config.engine == "sqlite" then
			local sqlite3 = require("lsqlite3")
			local sqlite = sqlite3.open(config["db_name"] .. ".sqlite3")
			sqlite:busy_timeout(1000)
			sqlite:exec([[PRAGMA journal_mode=WAL]])
			sqlite:exec([[PRAGMA synchronous=NORMAL]])
			sqlite:exec([[
				CREATE TABLE IF NOT EXISTS "migrations"
				(
					id integer PRIMARY KEY,
					filename VARCHAR
				);

				CREATE UNIQUE INDEX idx_migrations_filename ON migrations (filename);
			]])
		elseif config.engine == "surrealdb" then
			local _Surreal = require("db.surrealdb")
			Surreal[config.name] = _Surreal.new(config)
		end
	end
end

function HandleSqliteFork(db_config)
	if db_config["engine"] == "sqlite" then
		Sqlite3 = require("lsqlite3")
		Sqlite = Sqlite3.open(db_config[BeansEnv]["db_name"] .. ".sqlite3")
		Sqlite:busy_timeout(1000)
		Sqlite:exec([[PRAGMA journal_mode=WAL]])
		Sqlite:exec([[PRAGMA synchronous=NORMAL]])
	end
end

function PublicPath(path)
	if BeansEnv == "production" then
		return path .. "?" .. (LastModifiedAt[path] or 0)
	else
		return path .. "?" .. Rdtsc()
	end
end

function LoadPublicAssetsRecursively(path)
	local dir = unix.opendir(path)
	assert(dir ~= nil, "Error while opening path " .. path)

	while true do
		local file, kind = dir:read()
		if file == nil then
			break
		end
		if kind == unix.DT_DIR and file ~= "." and file ~= ".." then
			-- Recursively process subdirectories
			LoadPublicAssetsRecursively(path .. "/" .. file)
		elseif kind == unix.DT_REG and not file:match("^%.") then
			-- Process regular files (excluding hidden files)
			local relativePath = path:gsub("^public", "") .. "/" .. file
			LastModifiedAt[relativePath] = GetAssetLastModifiedTime(path .. "/" .. file)
		end
	end
	dir:close()
end

function RunCommand(command)
	if type(command) == "string" then
		command = string.split(command)
	end

	local prog = assert(Unix.commandv(command[1]))

	local output = ""
	local reader, writer = assert(Unix.pipe())
	if assert(Unix.fork()) == 0 then
		Unix.close(1)
		Unix.dup(writer)
		Unix.close(writer)
		Unix.close(reader)
		Unix.execve(prog, command, { "PATH=/bin" })
		Unix.exit(127)
	else
		Unix.close(writer)
		while true do
			local data, err = Unix.read(reader)
			if data then
				if data ~= "" then
					output = output .. data
				else
					break
				end
			elseif err:errno() ~= Unix.EINTR then
				Log(kLogWarn, tostring(err))
				break
			end
		end
		assert(Unix.close(reader))
		Unix.wait()
	end

	return output
end

function LoadCronsJobs(path)
	if os.date("%S") == "00" then -- run every minute
		path = path or "app/cronjobs"
		local dir = unix.opendir(path)
		assert(dir ~= nil, "Error while opening path " .. path)

		while true do
			local file, kind = dir:read()
			if kind == unix.DT_DIR and file ~= "." and file ~= ".." then
				LoadViewsRecursively(path .. "/" .. file)
			end
			if kind == unix.DT_REG then
				if string.match(file, "cron%.lua$") then
					if assert(unix.fork()) == 0 then
						package.loaded[file:gsub("%.lua", "")] = nil
						require(file:gsub("%.lua", ""))
						unix.exit(0)
					end
				end
			end

			if file == nil then
				break
			end
		end
		dir:close()
	end
end

function RefreshPageForDevMode()
	if BeansEnv == "development" then
		return [[<script src="/live_reload.js"></script>]]
	else
		return ""
	end
end

-- View Helpers
local function ExtractModelError(inputTable, allowedField)
	local messages = {}

	-- Collect messages for the allowed field
	for _, v in ipairs(inputTable) do
		if v.field == allowedField then
			table.insert(messages, v.message)
		end
	end

	return messages
end

local function DisplayErrorFor(model_errors, field, style)
	style = style or "color:red"
	local errors = ExtractModelError(model_errors, field)
	if #errors > 0 then
		for _, error in pairs(errors) do
			return [[<div style="%s">%s</div>]] % { style, error }
		end
	else
		return ""
	end
end

function TextField(name, field, model, options)
	options = options or {}
	local value = options.novalue == true and "" or model.data[field]
	local required = options.required == true and "required" or ""
	local type = options.password == true and "password" or "text"

	return [[
	<label class="font-bold" for="firstname">%s</label>
	<input type="%s" name="%s" value="%s" %s class="bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 border border-slate-300 dark:border-slate-600 rounded px-3 py-2 w-full focus:outline-none focus:ring-2 focus:ring-purple-500 dark:focus:ring-purple-400" />%s
	]] % { name, type, field, value or "", required, DisplayErrorFor(model.errors, field, options.error_style) }
end

function PasswordField(name, field, model, options)
	return TextField(name, field, model, table.merge(options, { password = true }))
end

function CheckboxField(field, model, options)
	options = options or {}
	return '%s<input type="checkbox" name="%s" %s>' % { DisplayErrorFor(model.errors, field, options.error_style), field, model.data[field] and "checked" or "" }
end
-- / View Helpers
