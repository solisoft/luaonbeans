RestApiUrl = ""

local function init(db_config)
  print(EncodeJson(db_config))
  RestApiUrl = db_config["url"] .. db_config["db_name"] .. "/"
end

local function read(collection, params, body)
  params = params or {}
  params['filters'] = params['filters'] or {}
  params['sort'] = params['sort'] or {}
  params['fields'] = params['fields'] or {}

  local filter = "?filter=" .. table.concat(params['filters'], ";")
  filter = filter .. "&sort=" .. table.concat(params['sort'], ";")
  filter = filter .. "&fields=" .. table.concat(params['fields'], ",")

  local method = "GET"
  local expand = ""

  local request_params = {
    method = method,
    headers = {
      ["Content-Type"] = "application/json"
    }
  }

  if body then
    request_params.body = EncodeJson(body) or ""
    method = "POST"
    expand = "/_expand"
  end

  local ok, h, body =
      Fetch(
        RestApiUrl .. collection .. expand .. filter,
        request_params
      )
  return DecodeJson(body)
end

local function write(collection, params)
  local ok, h, body =
      Fetch(
        RestApiUrl .. collection .. filter,
        {
          method = "POST",
          body = EncodeJson(params) or "",
          headers = {
            ["Content-Type"] = "application/json"
          }
        }
      )
  return DecodeJson(body)
end

local function delete(collection, params)
  local ok, h, body =
      Fetch(
        RestApiUrl .. collection .. filter,
        {
          method = "DELETE",
          body = EncodeJson(params) or "",
          headers = {
            ["Content-Type"] = "application/json"
          }
        }
      )
  return DecodeJson(body)
end

local function update(collection, filters, params)
  local filter = ""
  if type(filters) == "table" then
    filter = "?filter=" .. table.concat(filters, ";")
  end

  local ok, h, body =
      Fetch(
        RestApiUrl .. collection .. filter,
        {
          method = "PUT",
          body = EncodeJson(params) or "",
          headers = {
            ["Content-Type"] = "application/json"
          }
        }
      )
  return DecodeJson(body)
end

return {
  read = read,
  write = write,
  delete = delete,
  update = update,
  init = init
}