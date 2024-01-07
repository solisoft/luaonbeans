comment = {}

-- A kind of before_each only: %w(edit update show) :)
if table.contains({ "edit", "update", "show" }, params.action) then
  comment = adb.GetDocument("comments/" .. params.id)
end

-- Here a method to be more DRI
local function load_index()
  local data = adb.Aql([[
    FOR post IN posts FILTER post._key == TO_STRING(@key)
    LET comments = (
      FOR comment IN comments FILTER comment.post_key == post._key
      SORT comment._key ASC RETURN comment
    )
    RETURN { post, comments }
  ]], { key = params.post_id }).result[1]

  if data then
    Page('comments/index', 'app', { comments = data.comments })
  else
    SetStatus(404)
    Route("404.html")
    return
  end
end

local app = {
  -- GET comments#index => /comments
  index = function() load_index() end,

  -- GET comments#new => /comments/new
  new = function() Page('comments/new', 'app') end,

  -- GET comments#show => /comments/:id
  show = function() Page('comments/show', 'app', { comment = comment }) end,

  -- GET comments#edit => /comments/:id/edit
  edit = function() Page('comments/edit', 'app', { comment = comment }) end,

  -- PUT comments#update => comments/:id
  update = function()
    local bodyParams = GetBodyParams()
    bodyParams.post_key = params.post_id

    local record = adb.UpdateDocument("comments/" .. params.id, bodyParams)

    if record.error then
      Page('comments/edit', 'app', { comment = table.merge(bodyParams, { _key = params.id }), record = record })
      return
    end

    RedirectTo("/posts/" .. params.post_id .. "/comments")
  end,

  -- comment comments#create => /comments
  create = function()
    local bodyParams = GetBodyParams()
    bodyParams.post_key = params.post_id

    local created_comment = adb.CreateDocument("comments", bodyParams)

    if created_comment.error then
      SetStatus(400)
      Page('comments/new', 'app', { comment = bodyParams })
      return
    end

    RedirectTo("/posts/" .. params.post_id .. "/comments")
  end,

  -- DELETE comments#delete => /comments/:id
  delete = function()
    adb.DeleteDocument("comments/" .. params.id)
    load_index()
  end
}

app[params.action]()
