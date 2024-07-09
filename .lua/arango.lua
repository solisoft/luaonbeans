ArangoAPI = ""
ArangoJWT = ""
LastDBConnect = GetTime()

local function Api_url(path)
  return ArangoAPI .. path
end

local function Api_run(path, method, params, headers)
  params = params or {}
  headers = headers or {}
  local ok, h, body =
      Fetch(
        Api_url(path),
        {
          method = method,
          body = EncodeJson(params),
          headers = table.append({ ["Authorization"] = "bearer " .. ArangoJWT }, headers)
        }
      )

  return DecodeJson(body), ok, h
end

local function Auth(db_config)
  local ok, headers, body =
      Fetch(
        db_config.url .. "/_open/auth",
        {
          method = "POST",
          body = '{ "username": "' .. db_config.username .. '", "password": "' .. db_config.password .. '" }'
        }
      )

  ArangoAPI = db_config.url .. "/_db/" .. db_config.db_name .. "/_api"

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

local function with_Params(endpoint, method, handle, params)
  params = params or {}
  return Api_run(endpoint .. handle, method, params)
end

local function without_Params(endpoint, method, handle)
  return Api_run(endpoint .. handle, method)
end

-- Documents

local function UpdateDocument(handle, params)
  return with_Params("/document/", "PATCH", handle, params)
end

local function CreateDocument(handle, params)
  return with_Params("/document/", "POST", handle, params)
end

local function GetDocument(handle)
  return without_Params("/document/", "GET", handle)
end

local function DeleteDocument(handle)
  return without_Params("/document/", "DELETE", handle)
end

---Collections

local function UpdateCollection(collection, params)
  return with_Params("/collection/", "PUT", collection .. "/properties", params)
end

local function RenameCollection(collection, params)
  return with_Params("/collection/", "PUT", collection .. "/rename", params)
end

local function CreateCollection(collection, options)
  options = options or {}
  local params = { name = collection }
  params = table.merge(params, options)
  return with_Params("/collection/", "POST", "", params)
end

local function CreateCollectionWithTimestamps(collection, options)
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

  return with_Params("/collection/", "POST", "", params)
end

local function GetCollection(collection)
  return without_Params("/collection/", "GET", collection)
end

local function DeleteCollection(collection)
  return without_Params("/collection/", "DELETE", collection)
end

local function TruncateCollection(collection, params)
  return with_Params("/collection/", "PUT", collection .. "/truncate", params)
end

-- Databases

local function CreateDatabase(name, options)
  local params = { name = name, options = (options or {}) }
  return with_Params("/database", "POST", "", params)
end

local function DeleteDatabase(name)
  return without_Params("/database/", "DELETE", name)
end

-- Indexes

local function GetAllIndexes(collection)
  return without_Params("/index?collection=" .. collection, "GET", "")
end

local function CreateIndex(handle, params)
  return with_Params("/index?collection=" .. handle, "POST", "", params)
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

local function UpdateCacheConfiguration(params)
  return with_Params("/query-cache/properties", "PUT", "", params)
end

local function DeleteQueryCache()
  return without_Params("/query-cache", "DELETE", "")
end

-- Stream transactions
-- POST /_api/transaction/begin
local function BeginTransaction(params)
  return with_Params("/transaction/begin", "POST", "", params)
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
  CreateCollectionWithTimestamps = CreateCollectionWithTimestamps,
  DeleteCollection = DeleteCollection,
  PatchCollection = UpdateCollection,
  TruncateCollection = TruncateCollection,
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
  RefreshToken = RefreshToken
}
