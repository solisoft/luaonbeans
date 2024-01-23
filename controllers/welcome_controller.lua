local app = {
  -- GET welcome#index => /posts
  index = function()
    Page('welcome/index', 'app')
  end,

  create = function()
    --multipart_data = multipart(GetBody(), GetHeader("Content-Type"))
    --file = multipart_data:get("file")
    -- files = multipart_data:get("files[]") -- if multiple
    --content_type = multipart_data:get_content_type(file.headers)
    --filename = multipart_data:get_filename(file.headers)
    --arr = string.split(filename, ".")
    --ext = arr[#arr]
    --Write(EncodeJson(
    --  {
    --    ext = ext,
    --    filename = filename,
    --    content_type = content_type,
    --    size = #file.value
    --  }
    --))
    Write(EncodeJson(string.find(GetHeader("Content-Type"), "multipart")==1))
  end
    -- local status, err = Barf(Rand64(), multipart_data:get(filename).value)

}

return app[params.action]()

