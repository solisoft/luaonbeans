function Page(view, layout, bindVarsView, bindVarsLayout)
  layout = etlua.compile(LoadAsset("layouts/" .. layout .. "/index.html.etlua"))(bindVarsLayout or {})
  view = etlua.compile(LoadAsset("views/".. view ..".etlua"))(bindVarsView or {})
  Write(layout:gsub("@yield", view))
end

function Partial(partial, bindVars)
  bindVars = bindVars or {}
  local results = {}
  if bindVars.aql then
    req = adb.Aql(bindVars.aql, bindVars.bindVars or {})
    bindVars.results = req["result"]
    bindVars.extras = req["extras"]
  end

  return etlua.compile(LoadAsset("partials/" .. partial .. ".html.etlua"))(bindVars)
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

	local path = GetPath()
	local id = null
	local parser = null
	local matcher = null

	local extractedPatterns = extractPatterns(options.root)

	for _, pattern in ipairs(extractedPatterns) do
    options.root = options.root:gsub(pattern, (options[pattern:gsub(":", "")] or "([0-9a-zA-Z_\\-]+)"))
	end

	params["controller"] = name

	if(#extractedPatterns > 0) then
		parser = re.compile(options.root)
		matcher = {parser:search(path)}
		for i, match in ipairs(matcher) do
			if i > 1 then
				params[extractedPatterns[i - 1]:gsub(":","")] = match
			end
		end
	end

	if GetMethod() == "GET" then
		parser = re.compile("^" .. options.root .. name .. "$")
		matcher = parser:search(path)

		if matcher then
			params["action"] = "index"
			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end

    parser = re.compile("^" .. options.root .. name .. "/new$")
		matcher = parser:search(path)
		if matcher then
			params["action"] = "new"
			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end

		parser = re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
		matcher, params["id"] = parser:search(path)
		if matcher then
			params["action"] = "show"

			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end

		parser = re.compile(name .. "/([0-9a-zA-Z_\\-]+)/edit$")
		matcher, params["id"] = parser:search(path)
		if matcher then
			params["action"] = "edit"
      RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end
	end

	if GetMethod() == "POST" then
		parser = re.compile("^" ..  options.root ..name .. "$")
		matcher = parser:search(path)
		if matcher then
			params["action"] = "create"
			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end

		-- Use POST instead of PUT if needed
		parser = re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
		matcher, params["id"] = parser:search(path)
		if matcher then
			params["action"] = "update"
			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end
	end

	if GetMethod() == "PUT" or GetMethod() == "PATCH" then
		parser = re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
		matcher, params["id"] = parser:search(path)
		if matcher then
			params["action"] = "update"
			RoutePath("/controllers/" .. name .. "_controller.lua")
			return
		end
	end

	if GetMethod() == "DELETE" then
		parser = re.compile(name .. "/([0-9a-zA-Z_\\-]+)$")
		matcher, params["id"] = parser:search(path)
		if matcher then
			params["action"] = "delete"
			RoutePath("/controllers/" .. name .. "_controller.lua")
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

	params.controller = options.controller
	params.action = options.action

	if(#extractedPatterns > 0) then
		parser = re.compile(url)
		matcher = {parser:search(path)}
		for i, match in ipairs(matcher) do
			if i > 1 then
				params[extractedPatterns[i - 1]:gsub(":","")] = match
			end
		end
	end

	if GetMethod() == method then
		RoutePath("/controllers/" .. options.controller .. "_controller.lua")
		return
	else
		Route()
	end
end

function GetBodyParams()
  local body_params = {}
  for i, data in pairs(params) do
    if type(data) == "table" then body_params[data[1]] = data[2] end
  end

  return body_params
end

function RedirectTo(path, status)
	status = status or 301
	SetStatus(status)
	SetHeader("Location", path)
end