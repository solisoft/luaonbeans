ApiURL = ""
ArangoJWT = ""
LastDBConnect = GetTime()

local function Api_url(path)
  return ApiURL .. path
end

local function Api_run(path, method, Params, headers)
  Params = Params or {}
  headers = headers or {}
  local ok, h, body = Fetch(
    Api_url(path), {
      method = method,
      body = EncodeJson(Params),
      headers = table.append({ ["Authorization"] = "bearer " .. ArangoJWT }, headers)
    }
  )

  return DecodeJson(body), ok, h
end

local function Auth(db_config)
  local ok, headers, body = Fetch(
    db_config.url .. "/_open/auth", {
      method = "POST",
      body = "{ \"username\": \"" .. db_config.username .. "\", \"password\": \"" .. db_config.password .. "\" }"
    }
  )

  ApiURL = db_config.url .. "/_db/" .. db_config.db_name .. "/_api"

  if ok == 200 then
    ArangoJWT = DecodeJson(body)["jwt"]
  end

  return ArangoJWT
end

local function Raw_aql(stm)
  local body, status_code = Api_run("/cursor", "POST", stm)
  local result = body["result"]
  local has_more = body["hasMore"]
  local extra = body["extra"]

  while has_more do
    body = Api_run("/cursor/" .. body["id"], "PUT")
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

local function Aql(str, bindvars, options)
  bindvars = bindvars or {}
  options = options or { fullCount = true }

  local request = Raw_aql({ query = str, cache = true, bindVars = bindvars, options = options })
  return request
end

local function with_Params(endpoint, method, handle, Params)
  Params = Params or {}
  return Api_run(endpoint .. handle, method, Params)
end

local function without_Params(endpoint, method, handle)
  return Api_run(endpoint .. handle, method)
end

-- Documents

local function UpdateDocument(handle, Params)
  return with_Params("/document/", "PATCH", handle, Params)
end

local function CreateDocument(handle, Params)
  return with_Params("/document/", "POST", handle, Params)
end

local function GetDocument(handle)
  return without_Params("/document/", "GET", handle)
end

local function DeleteDocument(handle)
  return without_Params("/document/", "DELETE", handle)
end

---Collections

local function UpdateCollection(collection, Params)
  return with_Params("/collection/", "PUT", collection .. "/properties", Params)
end

local function RenameCollection(collection, Params)
  return with_Params("/collection/", "PUT", collection .. "/rename", Params)
end

local function CreateCollection(collection, options)
  options = options or {}
  local Params = { name = collection }
  Params = table.merge(Params, options)
  return with_Params("/collection/", "POST", "", Params)
end

local function GetCollection(collection)
  return without_Params("/collection/", "GET", collection)
end

local function DeleteCollection(collection)
  return without_Params("/collection/", "DELETE", collection)
end

-- Databases

local function CreateDatabase(name, options)
  local Params = { name = name, options = (options or {}) }
  return with_Params("/database", "POST", "", Params)
end

local function DeleteDatabase(name)
  return without_Params("/database/", "DELETE", name)
end

-- Indexes

local function GetAllIndexes(collection)
  return without_Params("/index?collection=" .. collection, "GET", "")
end

local function CreateIndex(handle, Params)
  return with_Params("/index?collection=" .. handle, "POST", "", Params)
end

local function DeleteIndex(handle)
  return without_Params("/index/", "DELETE", handle)
end

-- QueryCache

local function GetQueryCacheEntries()
  return without_Params("/query-cache/entries", "GET", "")
end

local function GetQueryCacheConfiguration()
  return without_Params("/query-cache/properties", "GET", "")
end

local function UpdateCacheConfiguration(Params)
  return with_Params("/query-cache/properties", "PUT", "", Params)
end

local function DeleteQueryCache()
  return without_Params("/query-cache", "DELETE", "")
end

-- Stream transactions
-- POST /_api/transaction/begin
local function BeginTransaction(Params)
  return with_Params("/transaction/begin", "POST", "", Params)
end

local function CommitTransaction(transaction_id)
  return without_Params("/transaction/", "PUT", transaction_id)
end

local function AbortTransaction(transaction_id)
  return without_Params("/transaction/", "DELETE", transaction_id)
end

local function RefreshToken(db_config)
  if GetTime() - LastDBConnect > 600 then
    Auth(db_config)
    LastDBConnect = GetTime()
  end
end

return {
  Aql = Aql,
  Auth = Auth,
  GetDocument = GetDocument,
  UpdateDocument = UpdateDocument,
  CreateDocument = CreateDocument,
  DeleteDocument = DeleteDocument,
  PatchDocument = UpdateDocument,

  GetCollection = GetCollection,
  UpdateCollection = UpdateCollection,
  RenameCollection = RenameCollection,
  CreateCollection = CreateCollection,
  DeleteCollection = DeleteCollection,
  PatchCollection = UpdateCollection,

  GetAllIndexes = GetAllIndexes,
  CreateIndex = CreateIndex,
  DeleteIndex = DeleteIndex,

  CreateDatabase = CreateDatabase,
  DeleteDatabase = DeleteDatabase,

  BeginTransaction = BeginTransaction,
  CommitTransaction = CommitTransaction,
  AbortTransaction = AbortTransaction,

  GetQueryCacheEntries = GetQueryCacheEntries,
  GetQueryCacheConfiguration = GetQueryCacheConfiguration,
  UpdateCacheConfiguration = UpdateCacheConfiguration,
  DeleteQueryCache = DeleteQueryCache,

  RefreshToken = RefreshToken,
}
