-- cratedb wrapper
--
-- Usage : Crate.sql("select * from customers")
--
-- Returns : { duration = 0.001, result = { { id = 1, name = "John" }, { id = 2, name = "Jane" } } }
--
local crate_config = nil

local function init(config)
  crate_config = config
end

local function sql(sql, bindVars)
  local ok, headers, body = Fetch(
    crate_config["url"] .. "/_sql",
    {
      method = "POST",
      body = EncodeJson({ stmt= sql, bind_vars= bindVars }),
      headers = {
        ["Accept"] = "application/json"
      }
    }
  )

  if (ok == 200) then
    local response = DecodeJson(body)
    local duration = response["duration"]

    local data = {}
    local columns = response["cols"]

    for j = 1, #response["rows"] do
      local row = response["rows"][j]
      local rowData = {}
      for k = 1, #columns do rowData[columns[k]] = row[k] end
      data[j] = rowData
    end

    return {
      duration = duration,
      result = data
    }
  else
    return DecodeJson(body)
  end
end

return {
  sql = sql,
  init = init
}
