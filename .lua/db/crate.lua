-- very basic cratedb wrapper
--
-- Usage :
--   local Crate = require("crate")
--   local crate = Crate.new(config)
--   crate.sql("select * from customers")
--
-- Returns : { duration = 0.001, result = { { id = 1, name = "John" }, { id = 2, name = "Jane" } } }
--
Crate = {}
Crate.__index = {}

function Crate.new(db_config)
  local self = setmetatable({}, Crate)
  self._db_config = db_config

  return self
end

function Crate:sql(sql, bindVars)
  local ok, headers, body = Fetch(
    self._db_config["url"] .. "/_sql",
    {
      method = "POST",
      body = EncodeJson({ stmt= sql, bind_vars= bindVars }) or "",
      headers = {
        ["Accept"] = "application/json"
      }
    }
  )

  if (ok == 200) then
    local response = DecodeJson(body) or {}
    local duration = response["duration"]

    local data = {}
    local rows = response["rows"] or {}
    local columns = response["cols"] or {}

    for j = 1, #rows do
      local row = response["rows"][j] or {}
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

return Crate
