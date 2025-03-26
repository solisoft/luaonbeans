function PageAQL(view, layout, bindVarsView, bindVarsLayout)
  if (BeansEnv == "development") then
    Views["app/views/layouts/" .. layout .. "/index.html.etlua"] = Etlua.compile(LoadAsset("app/views/layouts/" ..
      layout .. "/index.html.etlua"))
  end

  layout = Views["app/views/layouts/" .. layout .. "/index.html.etlua"](bindVarsLayout or {})

  local content
  if view:find("%%") then
    content = layout:gsub("@yield", view:gsub("%%", "%%%%"))
  else
    content = layout:gsub("@yield", view)
  end
  local etag = EncodeBase64(Md5(content))

  if etag == GetHeader("If-None-Match") then
    SetStatus(304)
  else
    SetHeader("Etag", etag)
    Write(content)
  end
end


function CreateComponent(component)
  local page_content = ""

  if component.component ~= "page" and LoadAsset("app/views/partials/components/" .. component.component .. ".html.etlua") then
    local widget = Partial("components/" .. component.component, { component = component })
    page_content = page_content .. widget
  end
  return page_content
end

function HandleAqlPage(aql, use_layout, write)
  if write == nil then write = true end
  if use_layout == nil then use_layout = true end

  local data = Adb.Aql(aql)

  local layout = ""
  local page_title = ""
  local page_description = ""
  local page_keywords = ""
  local page_author = ""
  local page_canonical = ""
  local page_image = ""
  local page_url = ""
  local page_content = ""

  if data.result == nil then
    local error = "<pre class=\"col-span-12\"><code>Error on AQL request : \n" .. EncodeJson(data, { pretty = true }) .."</code></pre>"
    if write then Write(error) end
    return error
  end

  for key, item in pairs(data.result[1]) do
    if #item == 0 then
      if item.component == "page" then
        page_title = item.title
        page_description = item.description
        page_keywords = item.keywords
        page_author = item.author
        page_canonical = item.canonical
        page_image = item.image
        page_url = item.url
      else
        page_content = page_content .. CreateComponent(item)
      end
    else
      for _, component in pairs(item) do
        page_content = page_content .. CreateComponent(component)
      end
    end
  end

  if use_layout then
    PageAQL(page_content, "app", {}, { title = page_title, page_content = page_content })
  else
    if write then
      Write(page_content)
    end
  end

  return page_content
end

function DisplayAqlPage(filename)
  local aql = LoadAsset("aqlpages/" .. filename .. ".aql")
  local page_content = HandleAqlPage(aql, false, false)

  return page_content
end
