Routes = {}

function Page(view, layout, bindVarsView, bindVarsLayout)
  layout = Etlua.compile(LoadAsset("app/views/layouts/" .. layout .. "/index.html.etlua"))(bindVarsLayout or {})
  view = Etlua.compile(LoadAsset("app/views/" .. view .. ".etlua"))(bindVarsView or {})

  local content = layout:gsub("@yield", view)
  local etag = EncodeBase64(Md5(content))

  if etag == GetHeader("If-None-Match") then
    SetStatus(304)
  else
    SetHeader('Etag', etag)
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

function Resource(name, options)
  options = options or { root = "" }
  options.root = options.root or ""
  options.root = options.root .. "/"
  local routes = options.only or { "index", "new", "show", "create", "update", "edit", "delete" }

  local path = GetPath()
  local parser = nil
  local matcher = nil

  local extractedPatterns = extractPatterns(options.root)

  for _, pattern in ipairs(extractedPatterns) do
    options.root = options.root:gsub(pattern, (options[pattern:gsub(":", "")] or "([0-9a-zA-Z_\\-]+)"))
  end

  Params["controller"] = name

  if (#extractedPatterns > 0) then
    parser = Re.compile(options.root)
    matcher = { parser:search(path) }
    for i, match in ipairs(matcher) do
      if i > 1 then
        Params[extractedPatterns[i - 1]:gsub(":", "")] = match
      end
    end
  end

  if GetMethod() == "GET" then
    parser = Re.compile("^" .. options.root .. name .. "$")
    matcher = parser:search(path)

    if matcher and table.contains(routes, "index") then
      Params["action"] = "index"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end

    parser = Re.compile("^" .. options.root .. name .. "/new$")
    matcher = parser:search(path)
    if matcher and table.contains(routes, "new") then
      Params["action"] = "new"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end

    parser = Re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
    matcher, Params["id"] = parser:search(path)
    if matcher and table.contains(routes, "show") then
      Params["action"] = "show"

      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end

    parser = Re.compile(name .. "/([0-9a-zA-Z_\\-]+)/edit$")
    matcher, Params["id"] = parser:search(path)
    if matcher and table.contains(routes, "edit") then
      Params["action"] = "edit"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end
  end

  if GetMethod() == "POST" then
    parser = Re.compile("^" .. options.root .. name .. "$")
    matcher = parser:search(path)
    if matcher and table.contains(routes, "create") then
      Params["action"] = "create"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end

    -- Use POST instead of PUT if needed
    parser = Re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
    matcher, Params["id"] = parser:search(path)
    if matcher and table.contains(routes, "update") then
      Params["action"] = "update"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end
  end

  if GetMethod() == "PUT" or GetMethod() == "PATCH" then
    parser = Re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
    matcher, Params["id"] = parser:search(path)
    if matcher and table.contains(routes, "update") then
      Params["action"] = "update"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end
  end

  if GetMethod() == "DELETE" then
    parser = Re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
    matcher, Params["id"] = parser:search(path)
    if matcher and table.contains(routes, "delete") then
      Params["action"] = "delete"
      RoutePath("/app/controllers/" .. name .. "_controller.lua")
      return
    end
  end
end

function CustomRoute(method, url, options)
  local extractedPatterns = extractPatterns(url)
  local path = GetPath()

  for _, pattern in ipairs(extractedPatterns) do
    url = url:gsub(pattern, (options[pattern:gsub(":", "")] or "([0-9a-zA-Z_\\-]+)"))
  end

  if (#extractedPatterns > 0) then
    local parser = Re.compile(url)
    local matcher = { parser:search(path) }
    for i, match in ipairs(matcher) do
      if i > 1 then
        Params[extractedPatterns[i - 1]:gsub(":", "")] = match
      end
    end
  end

  local parser = Re.compile("^" .. url .. "$")
  local matcher = parser:search(path)
  if matcher and GetMethod() == method then
    Params.controller = options.controller
    Params.action = options.action

    RoutePath("/app/controllers/" .. options.controller .. "_controller.lua")
    return
  end
end

function GetBodyParams()
  local body_Params = {}
  for i, data in pairs(Params) do
    if type(data) == "table" then body_Params[data[1]] = data[2] end
  end

  return body_Params
end

function RedirectTo(path, status)
  status = status or 301
  SetStatus(status)
  SetHeader("Location", path)
end

function WriteJSON(object)
  SetHeader('Content-Type', 'application/json; charset=utf-8')
  local json = EncodeJson(object)
  local etag = EncodeBase64(Md5(json))

  if etag == GetHeader("If-None-Match") then
    SetStatus(304)
  else
    SetHeader('Etag', etag)
    Write(json)
  end
end
