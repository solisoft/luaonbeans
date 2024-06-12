Routes = {}

function Page(view, layout, bindVarsView, bindVarsLayout)
  layout = Etlua.compile(LoadAsset("app/views/layouts/" .. layout .. "/index.html.etlua"))(bindVarsLayout or {})
  view = Etlua.compile(LoadAsset("app/views/" .. view .. ".etlua"))(bindVarsView or {})

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

  return Etlua.compile(LoadAsset("app/views/partials/" .. partial .. ".html.etlua"))(bindVars)
end

function extractPatterns(inputStr)
  local patterns = {}
  for pattern in string.gmatch(inputStr, "(:[%w_]+)") do
    table.insert(patterns, pattern)
  end
  return patterns
end

function assignRoute(method, name, options, value)
  local current = Routes[method]
  options["parent"] = options["parent"] or {}

  for i = 1, #options["parent"] do
    local parent = options["parent"][i]

    current[parent] = current[parent] or {}
    current[parent][":var"] = current[parent][":var"] or {}
    if options["type"] == "member" and i == #options["parent"] then
      current = current[parent][":var"]
    else
      current = current[parent]
    end
  end

  current[name] = value
end

function Resource(name, options)
  options = options or {}
  options["parent"] = options["parent"] or {}
  options["only"] = options["only"] or { "index", "show", "new", "create", "edit", "update", "delete" }
  local only = options["only"]
  Routes["GET"] = Routes["GET"] or {}
  Routes["POST"] = Routes["POST"] or {}
  Routes["PUT"] = Routes["PUT"] or {}
  Routes["DELETE"] = Routes["DELETE"] or {}

  local get = {}
  if table.contains(only, "index") then get[""] = name .. "#index" end
  if table.contains(only, "new") then  get["new"] = name .. "#new" end
  get[":var"] = {
    [":name"] = options["var_name"] or "id",
    [":regex"] = options["var_regex"] or "([0-9a-zA-Z_\\-]+)"
  }
  if table.contains(only, "edit")  then get[":var"]["edit"] = name .. "#edit" end
  if table.contains(only, "show")  then get[":var"][""] = name .. "#show" end
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
  if table.contains(only, "delete") then delete[""] = name .. "#delete" end
  assignRoute("DELETE", name, options, delete)
end

function CustomRoute(method, name, endpoint, options)
  options = options or {}

  assignRoute(method, name, options, endpoint)
end

function DefineRoutes(path, method)
  if method == "PATCH" then method = "PUT" end

  local recognized_route = Routes[method]

  local route_found = false

  if path == "/" then
    recognized_route = recognized_route[""]
  else
    for _, value in pairs(string.split(path, "/")) do
      if recognized_route[value] then
        recognized_route = recognized_route[value]
        route_found = true
      else
        if recognized_route[":var"] then
          recognized_route = recognized_route[":var"]
          local parser = Re.compile(recognized_route[":regex"])
          local matcher = { parser:search(value) }
          for i, match in ipairs(matcher) do
            if i > 1 then
              Params[recognized_route[":name"]] = match
            end
          end
        end
      end
    end
    if type(recognized_route) == "table" and route_found then
      recognized_route = recognized_route[""]
    else
      if route_found == false then recognized_route = nil end
    end
  end

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
