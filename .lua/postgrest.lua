local PGPGRestApiUrl = ""
local PGRestHeaders = {}

local function init(db_config)
  PGRestApiUrl = db_config["url"]
  PGRestHeaders = {
    ["Authorization"] = "Bearer " .. db_config["jwt_token"],
    ["Content-Type"] = "application/json"
  }
end

local function count(path)
  local ok, h, body = Fetch(PGRestApiUrl .. path, { headers = table.merge(PGRestHeaders, { Prefer = "count=exact" }) })
  return ok, tonumber(string.split(h["Content-Range"], "/")[2])
end

local function read(path)
  local ok, h, body = Fetch(PGRestApiUrl .. path, { headers = PGRestHeaders })
  return ok, DecodeJson(body)
end

local function update(path, data)
  local ok, h, body = Fetch(PGRestApiUrl .. path, {
    method = "PATCH",
    body = EncodeJson(data),
    headers = PGRestHeaders
  })
  return ok, DecodeJson(body)
end

local function insert(path, data)
  local ok, h, body = Fetch(PGRestApiUrl .. path, {
    method = "POST",
    body = EncodeJson(data),
    headers = table.merge(PGRestHeaders, { Prefer = "return=representation" })
  })
  return ok, body
end

local function delete(path, data)
  local ok, h, body = Fetch(PGRestApiUrl .. path, {
    method = "DELETE",
    headers = PGRestHeaders
  })
  return ok, DecodeJson(body)
end

return {
  init = init,
  count = count,
  read = read,
  insert = insert,
  update = update,
  delete = delete,
  upsert = upsert
}
