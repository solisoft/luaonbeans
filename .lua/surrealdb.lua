-- surrealdb wrapper
--
-- Usage : Surreal.sql("select * from customers").result
--

SurrealToken = ""
SurrealConfig = {}

LastDBConnect = GetTime()

local function auth(db_config)
  SurrealConfig = db_config

  local ok, headers, body =
      Fetch(
        SurrealConfig.url .. "/signin",
        {
          method = "POST",
          body = EncodeJson({
            user = db_config.username,
            pass = db_config.password
          }) or "",
          headers = {
            ["Accept"] = "application/json"
          }
        }
      )

  if ok == 200 then
    SurrealToken = DecodeJson(body)["token"]
  end

  return SurrealToken
end

local function surreal_sql(sql)
  local ok, headers, body =
      Fetch(
        SurrealConfig.url .. "/sql",
        {
          method = "POST",
          body = sql,
          headers = {
            ["Authorization"] = "Bearer " .. SurrealToken,
            ["NS"] = SurrealConfig.ns,
            ["DB"] = SurrealConfig.db,
            ["Accept"] = "application/json"
          }
        }
      )

  return DecodeJson(body)[1]
end

local function refresh_token()
  if GetTime() - LastDBConnect > 600 then
    auth(SurrealConfig)
    LastDBConnect = GetTime()
  end
end

return {
  auth = auth,
  sql = surreal_sql,
  refresh_token = refresh_token
}
