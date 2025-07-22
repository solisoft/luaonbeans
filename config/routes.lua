Routes = { ["GET"] = {
    [""] = "welcome#index",
    ["pdf"] = "welcome#pdf",
    ["chart"] = "welcome#chart"
  }
}

CustomRoute("POST", "/upload/:collection/:key/:field", "uploads#upload")
CustomRoute("GET", "/o/:uuid/:format", "uploads#original_image")
CustomRoute("GET", "/r/:uuid/:width/:format", "uploads#resized_image_x", { [":width"] = "([0-9]+)" })
CustomRoute("GET", "/xy/:uuid/:width/:height/:format", "uploads#resized_image_x_y", { [":width"] = "([0-9]+)", [":height"] = "([0-9]+)" })

-- CustomRoute("GET", "demo/with/:id/nested/:demo/route", "welcome#ban", {
--	[":demo"] = "([0-9]+)" -- you can define regex per params
-- })

-- CustomRoute("GET", "ban*", "welcome#ban") -- use splat

-- Resource("customers", {
--	 var_name = "customer_id",				 -- default value is "id"
--	 var_regex = "([0-9a-zA-Z_\\-]+)", -- default value
-- })
-- -- Will generate :
-- -- GET /customers										-- customers#index
-- -- GET /customers/new								-- customers#new
-- -- GET /customers/:customer_id			 -- customers#show
-- -- POST /customers									 -- customers#create
-- -- GET /customers/:customer_id/edit	-- customers#edit
-- -- PUT /customers/:customer_id			 -- customers#update
-- -- DELETE /customers/:customer_id		-- customers#delete
--
-- CustomRoute("GET", "ban", "customers#ban", {
--	 parent = { "customers" },
--	 type = "member", -- collection or member -- customers#ban
-- })
-- -- Will generate :
-- -- GET /customers/:id/ban
--
-- Resource("comments", {
--	 var_name = "comment_id",					-- default value is "id"
--	 var_regex = "([0-9a-zA-Z_\\-]+)", -- default value
--	 parent = { "customers" }
-- })
-- -- Will generate :
-- -- GET /customers/:customer_id/comments									 -- comments#index
-- -- GET /customers/:customer_id/comments/new							 -- comments#new
-- -- GET /customers/:customer_id/comments/:comment_id			 -- comments#show
-- -- POST /customers/:customer_id/comments									-- comments#create
-- -- GET /customers/:customer_id/comments/:comment_id/edit	-- comments#edit
-- -- PUT /customers/:customer_id/comments/:comment_id			 -- comments#update
-- -- DELETE /customers/:customer_id/comments/:comment_id		-- comments#delete

-- Resource("likes", {
--	 var_name = "like_id",					-- default value is "id"
--	 var_regex = "([0-9a-zA-Z_\\-]+)", -- default value
--	 parent = { "customers", "comments" }
-- })
-- -- Will generate :
-- -- GET /customers/:customer_id/comments/:comment_id/likes								-- likes#index
-- -- GET /customers/:customer_id/comments/:comment_id/likes/new						-- likes#new
-- -- GET /customers/:customer_id/comments/:comment_id/likes/:like_id			 -- likes#show
-- -- POST /customers/:customer_id/comments/:comment_id/likes							 -- likes#create
-- -- GET /customers/:customer_id/comments/:comment_id/likes/:like_id/edit	-- likes#edit
-- -- PUT /customers/:customer_id/comments/:comment_id/likes/:like_id			 -- likes#update
-- -- DELETE /customers/:customer_id/comments/:comment_id/likes/:like_id		-- likes#delete

-- Resource("books", {
--	 var_name = "book_id",
--	 var_regex = "([0-9a-zA-Z_\\-]+)",
--	 parent = { "customers" },
--	 only = { "index", "show" },
-- })
-- -- Will generate :
-- -- GET /customers/:customer_id/books									 -- books#index
-- -- GET /customers/:customer_id/books/:book_id			 -- books#show