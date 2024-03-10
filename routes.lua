local function routes()
  -- Routes
  ---- Basic CRUD
  -- Resource("posts")
  ---- Nested CRUD
  -- Resource("comments", { root = "/posts/:post_id", post_id = "([0-9]+)" })
  ---- Custom Ruute
  -- CustomRoute("GET", "/posts/:post_id/offline", {
  -- 	post_id = "([0-9]+)", controller = "posts", action = "offline"
  -- })
  ---- define root route

  if GetPath() == "/" then
    Params.action = "index"
    RoutePath("/app/controllers/welcome_controller.lua")
  end

  -- if GetPath() == "/upload" and GetMethod() == "POST" then
  -- 	Params.action = "create"
  -- 		RoutePath("/controllers/welcome_controller.lua")
  -- end

  if Params.action == nil then
    if RoutePath("/public" .. GetPath()) == false then
      SetStatus(404)
      Page("404", "app")
    end
  end
end

return routes
