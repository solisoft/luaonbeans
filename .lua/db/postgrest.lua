PGRest = {}
PGRest.__index = PGRest

function PGRest.new(db_config)
  local self = setmetatable({}, PGRest)
  self._db_config = db_config
  self._api_url = ""
  self._headers = {}
  self:init()

  return self
end

function PGRest:init()
  self._api_url = self._db_config["url"]
  self._headers = {
    ["Authorization"] = "Bearer " .. self._db_config["jwt_token"],
    ["Content-Type"] = "application/json"
  }
end

function PGRest:count(path)
  local ok, h, body = Fetch(self._api_url .. path, { headers = table.merge(self._headers, { Prefer = "count=exact" }) })
  return ok, tonumber(string.split(h["Content-Range"], "/")[2])
end

function PGRest:read(path)
  local ok, h, body = Fetch(self._api_url .. path, { headers = self._headers })
  return ok, DecodeJson(body)
end

function PGRest:update(path, data)
  local ok, h, body = Fetch(self._api_url .. path, {
    method = "PATCH",
    body = data and EncodeJson(data) or {},
    headers = self._headers
  })
  return ok, DecodeJson(body)
end

function PGRest:insert(path, data)
  local ok, h, body = Fetch(self._api_url .. path, {
    method = "POST",
    body = data and EncodeJson(data) or {},
    headers = table.merge(self._headers, { Prefer = "return=representation" })
  })
  return ok, body
end

function PGRest:delete(path, data)
  local ok, h, body = Fetch(self._api_url .. path, {
    method = "DELETE",
    headers = self._headers
  })
  return ok, DecodeJson(body)
end

return PGRest
