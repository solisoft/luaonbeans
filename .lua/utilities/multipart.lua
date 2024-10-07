-- Prepare MultiPart Params and merge everything in Params
PrepareMultiPartParams = function()
  if GetHeader("Content-Type") ~= nil and string.find(GetHeader("Content-Type"), "multipart") ~= nil then
    local keys = {}
    local multipart_data = Multipart(GetBody(), GetHeader("Content-Type"))

    for k, _ in pairs(multipart_data:get_all_with_arrays()) do
      table.insert(keys, k)
    end

    for _, k in pairs(keys) do
      local param = multipart_data:get(k)
      if #param.headers == 1 then
        Params[k] = param.value
      else
        local m = string.find(k, "%[%]")
        if m ~= nil and m > 1 then
          local k_str = string.gsub(k, "%[%]", "")
          Params[k_str] = {}
          for _, part in pairs(multipart_data:get_as_array(k)) do
            local content_type = multipart_data:get_content_type(part.headers)
            local filename = multipart_data:get_filename(part.headers)
            local ext = GetFileExt(content_type)
            if ext then
              table.insert(Params[k_str], {
                ext = ext,
                filename = filename,
                content_type = content_type,
                size = #part.value,
                content = part.value
              })
            end
          end
        else
          local content_type = multipart_data:get_content_type(param.headers)
          local filename = multipart_data:get_filename(param.headers)
          local ext = GetFileExt(content_type)
          if ext then
            Params[k] = {
              ext = ext,
              filename = filename,
              content_type = content_type,
              size = #param.value,
              content = param.value
            }
          end
        end
      end
    end
  end
end

GetFileExt = function(content_type)
  local allowed_types = {
    ["image/gif"] = "gif",
    ["image/jpeg"] = "jpg",
    ["image/png"] = "png",
    ["image/svg+xml"] = "svg",
    ["image/webp"] = "webp",
    ["image/x-icon"] = "ico",

    ["video/mp4"] = "mp4",
    ["video/mpeg"] = "mpeg",
    ["video/ogg"] = "ogv",
    ["video/quicktime"] = "mov",
    ["video/webm"] = "webm",
    ["video/x-flv"] = "flv",
    ["video/x-mng"] = "mng",
    ["video/x-ms-asf"] = "asx",
    ["video/x-ms-wmv"] = "wmv",
    ["video/x-msvideo"] = "avi",

    ["application/pdf"] = "pdf",
    ["text/plain"] = "txt"
  }
  return allowed_types[content_type]
end
