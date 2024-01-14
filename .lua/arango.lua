api_url = ""
arango_jwt = ""
last_db_connect = GetTime()

local function Table_append(t1, t2)
	for k, v in ipairs(t2) do
		table.insert(t1, v)
	end

	return t1
end

local function Api_url(path)
	return api_url .. path
end

local function Api_run(path, method, params, headers)
	params = params or {}
	headers = headers or {}
	local ok, h, body = Fetch(
		Api_url(path), {
			method = method,
			body = EncodeJson(params),
			headers = Table_append({ ["Authorization"] = "bearer " .. arango_jwt }, headers)
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

	api_url = db_config.url .. "/_db/" .. db_config.db_name .. "/_api"

	if ok == 200 then
		arango_jwt = DecodeJson(body)["jwt"]
	end

	return arango_jwt
end

local function Raw_aql(stm)
	local body, status_code = Api_run("/cursor", "POST", stm)
	local result = body["result"]
	local has_more = body["hasMore"]
	local extra = body["extra"]

	while has_more do
		body = Api_run("/cursor/" .. body["id"], "PUT")
		result = Table_append(result, body["result"])
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

	local request = Raw_aql({ query = str, cache = true, bindVars = bindvars, options = options, cache = true })
	return request
end

local function with_params(endpoint, method, handle, params)
	params = params or {}
	return Api_run(endpoint .. handle, method, params)
end

local function without_params(endpoint, method, handle)
	params = params or {}
	return Api_run(endpoint .. handle, method)
end

-- Documents

local function UpdateDocument(handle, params)
	return with_params("/document/", "PATCH", handle, params)
end

local function CreateDocument(handle, params)
	return with_params("/document/", "POST", handle, params)
end

local function GetDocument(handle)
	return without_params("/document/", "GET", handle)
end

local function DeleteDocument(handle)
	return without_params("/document/", "DELETE", handle)
end

---Collections

local function UpdateCollection(collection, params)
	return with_params("/collection/", "PUT", collection, params)
end

local function CreateCollection(collection, options)
	local params = { name = collection, options = (options or {}) }
	return with_params("/collection/", "POST", "", params)
end

local function GetCollection(collection)
	return without_params("/collection/", "GET", collection)
end

local function DeleteCollection(collection)
	return without_params("/collection/", "DELETE", collection)
end

-- Databases

local function CreateDatabase(name, options)
	local params = { name = name, options = (options or {}) }
	return with_params("/database", "POST", "", params)
end

local function DeleteDatabase(name)
	return without_params("/database/", "DELETE", name)
end

-- Indexes

local function GetAllIndexes(collection)
	return without_params("/index?collection=" .. collection, "GET", "")
end

local function CreateIndex(handle, params)
	return with_params("/index?collection=" .. handle, "POST", "", params)
end

local function DeleteIndex(handle)
	return without_params("/index/", "DELETE", handle)
end

-- QueryCache

local function GetQueryCacheEntries()
	return without_params("/query-cache/entries", "GET", "")
end

local function GetQueryCacheConfiguration()
	return without_params("/query-cache/properties", "GET", "")
end

local function UpdateCacheConfiguration(params)
	return with_params("/query-cache/properties", "PUT", "", params)
end

local function DeleteQueryCache()
	return without_params("/query-cache", "DELETE", "")
end

-- Stream transactions
-- POST /_api/transaction/begin
local function BeginTransaction(params)
	return with_params("/transaction/begin", "POST", "", params)
end

local function CommitTransaction(transaction_id)
	return without_params("/transaction/", "PUT", transaction_id)
end

local function AbortTransaction(transaction_id)
	return without_params("/transaction/", "DELETE", transaction_id)
end

local function RefreshToken(db_config)
	if GetTime() - last_db_connect > 600 then
		Auth(db_config)
		last_db_connect = GetTime()
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

	UpdateCollection = UpdateCollection,
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
