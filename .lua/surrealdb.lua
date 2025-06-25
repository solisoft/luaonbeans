-- surrealdb wrapper
--
-- Usage : Surreal.sql("select * from customers").result
--
SurrealDB = {}
SurrealDB.__index = SurrealDB

function SurrealDB.new(db_config)
	local self = setmetatable({}, SurrealDB)
	self._surrealToken = ""
	self._surrealConfig = {}
	self._db_config = db_config
	self._lastDBConnect = GetTime()
	self:auth()

	return self
end

function SurrealDB:auth()
	local ok, headers, body =
			Fetch(
				self._db_config.url .. "/signin",
				{
					method = "POST",
					body = EncodeJson({
						user = self._db_config.username,
						pass = self._db_config.password
					}) or "",
					headers = {
						["Accept"] = "application/json"
					}
				}
			)

	if ok == 200 then
		self._surrealToken = DecodeJson(body)["token"]
	end

	return self._surrealToken
end

function SurrealDB:surreal_sql(sql)
	local ok, headers, body =
			Fetch(
				self._db_config.url .. "/sql",
				{
					method = "POST",
					body = sql,
					headers = {
						["Authorization"] = "Bearer " .. self._surrealToken,
						["NS"] = self._db_config.ns,
						["DB"] = self._db_config.db,
						["Accept"] = "application/json"
					}
				}
			)

	return DecodeJson(body)[1]
end

function SurrealDB:refresh_token()
	if GetTime() - self._lastDBConnect > 600 then
		self:auth()
		self._lastDBConnect = GetTime()
	end
end

return SurrealDB
