DB2Rest = {}
DB2Rest.__index = DB2Rest

function DB2Rest.new(db_config)
	local self = setmetatable({}, DB2Rest)
	self._db_config = db_config
	self._restApiUrl = db_config["url"] .. db_config["db_name"] .. "/"

	return self
end

function DB2Rest:read(collection, params, body)
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
				self._restApiUrl .. collection .. expand .. filter,
				request_params
			)
	return DecodeJson(body)
end

function DB2Rest:write(collection, params)
	local ok, h, body =
			Fetch(
				self._restApiUrl .. collection .. filter,
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

function DB2Rest:delete(collection, params)
	local ok, h, body =
			Fetch(
				self._restApiUrl .. collection .. filter,
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

function DB2Rest:update(collection, filters, params)
	local filter = ""
	if type(filters) == "table" then
		filter = "?filter=" .. table.concat(filters, ";")
	end

	local ok, h, body =
			Fetch(
				self._restApiUrl .. collection .. filter,
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

return DB2Rest
