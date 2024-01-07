post = {}
Posts = require("posts")

-- A kind of before_each only: %w(edit update show) :)
if table.contains({ "edit", "update", "show" }, params.action) then
  post = Posts.get(params.id)
end

-- Here a method to be more DRI
local function load_index()
  local posts = Posts.all()
  Page("posts/index", "app", { posts = posts })
end

local app = {
  -- GET posts#index => /posts
  index = function() load_index() end,

  -- GET posts#new => /posts/new
  new = function() Page("posts/new", "app") end,

  -- GET posts#show => /posts/:id
  show = function() Page("posts/show", "app", { post = post }) end,

  -- GET posts#edit => /posts/:id/edit
  edit = function() Page("posts/edit", "app", { post = post }) end,

  -- PUT posts#update => posts/:id
  update = function()
    local bodyParams = GetBodyParams()
    local record = Posts.update(params.id, bodyParams)

    if record.error then
      Page("posts/edit", "app", { post = table.merge(bodyParams, { _key = params.id }), record = record })
      return
    end

    RedirectTo("/posts")
  end,

  -- POST posts#create => /posts
  create = function()
    local bodyParams = GetBodyParams()
    local created_post = Posts.create(bodyParams)

    if created_post.error then
      SetStatus(400)
      Page("posts/new", "app", { post = bodyParams })
      return
    end

    RedirectTo("/posts")
  end,

  -- DELETE posts#delete => /posts/:id
  delete = function()
    Posts.destroy(params.id)
    load_index()
  end,

  offline = function()
    Write("Offline")
  end
}

assert(app[params.action] ~= null, "Missing method '" .. params.action .. "'!")
app[params.action]()
