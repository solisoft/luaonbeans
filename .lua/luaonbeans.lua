Routes = {}
Views = {}
Layouts = {}
Partials = {}

function Page(view, layout, bindVarsView, bindVarsLayout)
  if (BeansEnv == "dev" or Layouts["app/views/layouts/" .. layout .. "/index.html.etlua"] == nil) then
    Layouts["app/views/layouts/" .. layout .. "/index.html.etlua"] = LoadAsset("app/views/layouts/" ..
      layout .. "/index.html.etlua")
  end

  if (BeansEnv == "dev" or Views["app/views/" .. view .. ".etlua"] == nil) then
    Views["app/views/" .. view .. ".etlua"] = LoadAsset("app/views/" .. view .. ".etlua")
  end

  layout = Etlua.compile(Layouts["app/views/layouts/" .. layout .. "/index.html.etlua"])(bindVarsLayout or {})
  view = Etlua.compile(Views["app/views/" .. view .. ".etlua"])(bindVarsView or {})

  local content = layout:gsub("@yield", view)
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

  if (BeansEnv == "dev" or Partials["app/views/partials/" .. partial .. ".html.etlua"] == nil) then
    Partials["app/views/partials/" .. partial .. ".html.etlua"] = LoadAsset("app/views/partials/" ..
      partial .. ".html.etlua")
  end

  return Etlua.compile(Partials["app/views/partials/" .. partial .. ".html.etlua"])(bindVars)
end

function extractPatterns(inputStr)
  local patterns = {}
  for pattern in string.gmatch(inputStr, "(:[%w_]+)") do
    table.insert(patterns, pattern)
  end
  return patterns
end

local function assignRoute(method, name, options, value)
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

  local path = string.split(name, "/")
  for i = 1, #path do
    local v = path[i]

    if v:sub(1, 1) == ":" then
      current[":var"] = {
        [":name"] = v:sub(2),
        [":regex"] = options[v] or "([0-9a-zA-Z_\\-]+)"
      }
      if i == #path then current[":var"][""] = value end
      current = current[":var"]
    else
      current[v] = current[v] or {}
      if i == #path then
        current[v] = value
      end
      current = current[v]
    end
  end
end

function Resource(name, options)
  options = options or {}
  options["parent"] = options["parent"] or {}
  options["only"] = options["only"] or { "index", "show", "new", "create", "edit", "update", "delete" }
  options["type"] = "member"
  local only = options["only"]
  Routes["GET"] = Routes["GET"] or {}
  Routes["POST"] = Routes["POST"] or {}
  Routes["PUT"] = Routes["PUT"] or {}
  Routes["DELETE"] = Routes["DELETE"] or {}

  local get = {}
  if table.contains(only, "index") then get[""] = name .. "#index" end
  if table.contains(only, "new") then get["new"] = name .. "#new" end
  get[":var"] = {
    [":name"] = options["var_name"] or "id",
    [":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)"
  }
  if table.contains(only, "edit") then get[":var"]["edit"] = name .. "#edit" end
  if table.contains(only, "show") then get[":var"][""] = name .. "#show" end
  assignRoute("GET", name, options, get)

  local post = {}
  if table.contains(only, "create") then post[""] = name .. "#create" end
  post[":var"] = {
    [":name"] = options["var_name"] or "id",
    [":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)"
  }
  assignRoute("POST", name, options, post)

  local put = {}
  if table.contains(only, "update") then put[""] = name .. "#update" end
  put[":var"] = {
    [":name"] = options["var_name"] or "id",
    [":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)"
  }
  assignRoute("PUT", name, options, put)

  local delete = {}
  delete[":var"] = {
    [":name"] = options["var_name"] or "id",
    [":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)"
  }
  if table.contains(only, "delete") then delete[":var"][""] = name .. "#delete" end
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

function DefineRoutes(path, method)
  if method == "PATCH" then method = "PUT" end

  local recognized_route = Routes[method]

  local route_found = false
  local final_route = false

  Splat = {}
  if path == "/" then
    recognized_route = recognized_route[""]
  else
    for _, value in pairs(string.split(path, "/")) do
      if final_route == false then
        if recognized_route[value] or recognized_route[value .. "*"] then
          if recognized_route[value .. "*"] then final_route = true end
          recognized_route = recognized_route[value] or recognized_route[value .. "*"]
          route_found = true
        else
          route_found = false
          if recognized_route[":var"] then
            recognized_route = recognized_route[":var"]
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
      recognized_route = recognized_route[""]
    else
      if route_found == false then recognized_route = nil end
    end
  end

  Splat = tableSplat(Splat)

  if recognized_route ~= nil then
    recognized_route = string.split(recognized_route, "#")
    Params = table.merge(
      Params,
      { controller = recognized_route[1], action = recognized_route[2] }
    )
  end

  if Params.action == nil then
    if RoutePath("/public" .. GetPath()) == false then
      SetStatus(404)
      Page("404", "app")
      return
    end
  else
    RoutePath("/app/controllers/" .. Params.controller .. "_controller.lua")
    return
  end
end

function GetBodyParams()
  local body_Params = {}
  for i, data in pairs(Params) do
    if type(data) == "table" then
      body_Params[data[1]] = data[2]
    end
  end

  return body_Params
end

function RedirectTo(path, status)
  status = status or 301
  SetStatus(status)
  SetHeader("Location", path)
end

function WriteJSON(object)
  SetHeader("Content-Type", "application/json; charset=utf-8")
  local json = EncodeJson(object)
  local etag = EncodeBase64(Md5(json))

  if etag == GetHeader("If-None-Match") then
    SetStatus(304)
  else
    SetHeader("Etag", etag)
    Write(json)
  end
end

function InitDB(db_config)
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
  elseif (db_config["engine"] == "surrealdb") then
    Surreal = require("surrealdb")
    Surreal.auth(db_config[BeansEnv])
  end
end

function HandleSqliteFork(db_config)
  if db_config["engine"] == "sqlite" then
    Sqlite3 = require 'lsqlite3'
    Sqlite = Sqlite3.open('delupay-shop.sqlite3')
    Sqlite:busy_timeout(1000)
    Sqlite:exec [[PRAGMA journal_mode=WAL]]
    Sqlite:exec [[PRAGMA synchronous=NORMAL]]
  end
end
