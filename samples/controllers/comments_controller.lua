comment = {}
Comments = require("comments")

-- A kind of before_each only: %w(edit update show) :)
if table.contains({ "edit", "update", "show" }, Params.action) then
  comment = Comments.get(Params.id)
end

-- Here a method to be more DRI
local function load_index()
  local data = Comments.all()
  if data then
    Page("comments/index", "app", { comments = data.comments })
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
  new = function() Page("comments/new", "app") end,

  -- GET comments#show => /comments/:id
  show = function() Page("comments/show", "app", { comment = comment }) end,

  -- GET comments#edit => /comments/:id/edit
  edit = function() Page("comments/edit", "app", { comment = comment }) end,

  -- PUT comments#update => comments/:id
  update = function()
    local bodyParams = GetBodyParams()
    bodyParams.post_key = Params.post_id

    local record = Comments.update(Params.id, bodyParams)

    if record.error then
      Page("comments/edit", "app", { comment = table.merge(bodyParams, { _key = Params.id }), record = record })
      return
    end

    RedirectTo("/posts/" .. Params.post_id .. "/comments")
  end,

  -- comment comments#create => /comments
  create = function()
    local bodyParams = GetBodyParams()
    bodyParams.post_key = Params.post_id

    local created_comment = Comments.create(bodyParams)

    if created_comment.error then
      SetStatus(400)
      Page("comments/new", "app", { comment = bodyParams })
      return
    end

    RedirectTo("/posts/" .. Params.post_id .. "/comments")
  end,

  -- DELETE comments#delete => /comments/:id
  delete = function()
    Comments.destroy(Params.id)
    load_index()
  end
}

assert(app[Params.action] ~= nil, "Missing method '" .. Params.action .. "'!")
app[Params.action]()
