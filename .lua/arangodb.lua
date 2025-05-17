Adb = {}
Adb.__index = Adb

function Adb.new()
  local self = setmetatable({}, Adb)

  self._lastDBConnect = GetTime()
  self._arangoAPI = ""
  self._arangoJWT = ""
  self._db_config = null

  return self
end

function Adb:Api_url(path)
  return self._arangoAPI .. path
end

function Adb:infos()
  print(self._arangoAPI)
  print(self._arangoJWT)
end

function Adb:Api_run(path, method, params, headers)
  params = params or {}
  headers = headers or {}
  local ok, h, body =
      Fetch(
        self:Api_url(path),
        {
          method = method,
          body = EncodeJson(params) or "",
          headers = table.append({ ["Authorization"] = "bearer " .. self._arangoJWT }, headers)
        }
      )
  return DecodeJson(body), ok, h
end

function Adb:Auth(db_config)
  print(EncodeJson(db_config))
  if self._db_config == null then self._db_config = db_config end

  local ok, headers, body =
      Fetch(
        db_config.url .. "/_open/auth",
        {
          method = "POST",
          body = '{ "username": "' .. self._db_config.username .. '", "password": "' .. self._db_config.password .. '" }'
        }
      )

  self._arangoAPI = self._db_config.url .. "/_db/" .. self._db_config.db_name .. "/_api"
  print(self._arangoAPI)
  print(BeansEnv)
  if ok == 200 then
    self._arangoJWT = DecodeJson(body)["jwt"]
  end

  return self._arangoJWT
end

function Adb:Raw_aql(stm)
  local body, status_code = self:Api_run("/cursor", "POST", stm)
  local result = body["result"]
  local has_more = body["hasMore"]
  local extra = body["extra"]

  while has_more do
    body = self:Api_run("/cursor/" .. body["id"], "PUT")
    result = table.append(result, body["result"])
    has_more = body["hasMore"]
  end

  if result == nil then
    result = {}
  end

  if body.error then
    return body
  else
    return { result = result, extra = extra }
  end
end

function Adb:Aql(str, bindvars, options)
  bindvars = bindvars or {}
  options = options or { fullCount = true }

  local request = self:Raw_aql({ query = str, cache = true, bindVars = bindvars, options = options })
  return request
end

function Adb:with_Params(endpoint, method, handle, params)
  params = params or {}
  return self:Api_run(endpoint .. handle, method, params)
end

function Adb:without_Params(endpoint, method, handle)
  return self:Api_run(endpoint .. handle, method)
end

-- Documents

function Adb:UpdateDocument(handle, params)
  return self:with_Params("/document/", "PATCH", handle, params)
end

function Adb:CreateDocument(handle, params)
  return self:with_Params("/document/", "POST", handle, params)
end

function Adb:GetDocument(handle)
  return self:without_Params("/document/", "GET", handle)
end

function Adb:DeleteDocument(handle)
  return self:without_Params("/document/", "DELETE", handle)
end

---Collections

function Adb:UpdateCollection(collection, params)
  return self:with_Params("/collection/", "PUT", collection .. "/properties", params)
end

function Adb:RenameCollection(collection, params)
  return self:with_Params("/collection/", "PUT", collection .. "/rename", params)
end

function Adb:CreateCollection(collection, options)
  options = options or {}
  local params = { name = collection }
  params = table.merge(params, options)
  return self:with_Params("/collection/", "POST", "", params)
end

function Adb:CreateCollectionWithTimestamps(collection, options)
  options = options or {}
  local params = { name = collection }
  params = table.merge(params, options)
  params = table.merge(params, {
    ["computedValues"] = {
      {
        ["computeOn"] = { "insert" },
        expression = "RETURN DATE_NOW()",
        name = "c_at",
        overwrite = true
      },
      {
        ["computeOn"] = { "insert", "update" },
        expression = "RETURN DATE_NOW()",
        name = "u_at",
        overwrite = true
      }
    }
  })

  return self:with_Params("/collection/", "POST", "", params)
end

function Adb:GetCollection(collection)
  return self:without_Params("/collection/", "GET", collection)
end

function Adb:DeleteCollection(collection)
  return self:without_Params("/collection/", "DELETE", collection)
end

function Adb:TruncateCollection(collection, params)
  return self:with_Params("/collection/", "PUT", collection .. "/truncate", params)
end

-- Databases

function Adb:CreateDatabase(name, options, users)
  local params = { name = name, options = (options or {}) }
  if users then params.users = users end

  return self:with_Params("/database", "POST", "", params)
end

function Adb:DeleteDatabase(name)
  return self:without_Params("/database/", "DELETE", name)
end

-- Indexes

function Adb:GetAllIndexes(collection)
  return self:without_Params("/index?collection=" .. collection, "GET", "")
end

function Adb:CreateIndex(handle, params)
  return self:with_Params("/index?collection=" .. handle, "POST", "", params)
end

function Adb:DeleteIndex(handle)
  return self:without_Params("/index/", "DELETE", handle)
end

-- QueryCache

function Adb:GetQueryCacheEntries()
  return self:without_Params("/query-cache/entries", "GET", "")
end

function Adb:GetQueryCacheConfiguration()
  return self:without_Params("/query-cache/properties", "GET", "")
end

function Adb:UpdateCacheConfiguration(params)
  return self:with_Params("/query-cache/properties", "PUT", "", params)
end

function Adb:DeleteQueryCache()
  return self:without_Params("/query-cache", "DELETE", "")
end

-- Stream transactions
-- POST /_api/transaction/begin
function Adb:BeginTransaction(params)
  return self:with_Params("/transaction/begin", "POST", "", params)
end

function Adb:CommitTransaction(transaction_id)
  return self:without_Params("/transaction/", "PUT", transaction_id)
end

function Adb:AbortTransaction(transaction_id)
  return self:without_Params("/transaction/", "DELETE", transaction_id)
end

function Adb:RefreshToken()
  if GetTime() - self._lastDBConnect > 600 then
    self:Auth(self._db_config)
    self._lastDBConnect = GetTime()
  end
end

return Adb
