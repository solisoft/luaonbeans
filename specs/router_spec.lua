-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('router', function()
      lester.before(function()
        -- This function is run before every test.
      end)

      it('add resources', function()
        Resource("customers", { var_name = "customer_id" })
        Resource("comments", {
          var_name = "comment_id",          -- default value is "id"
          var_regex = "([0-9a-zA-Z_\\-]+)", -- default value
          parent = { "customers" }
        })

        Resource("likes", {
          var_name = "like_id",             -- default value is "id"
          var_regex = "([0-9a-zA-Z_\\-]+)", -- default value
          parent = { "customers", "comments" }
        })

        CustomRoute("GET", "ban", "customers#ban", {
          parent = { "customers" },
          type = "member", -- collection or member -- customers#ban
        })

        CustomRoute("GET", "refresh", "customers#refresh", {
          parent = { "customers" },
          type = "collection", -- collection or member -- customers#ban
        })

        CustomRoute("POST", "ban", "customers#ban")

        Resource("books", {
          only = { "index" },
        })

        Params = {}
        DefineRoutes("/customers", "GET")
        expect.equal(Params.controller, "customers")
        expect.equal(Params.action, "index")

        expect.equal(Routes["GET"]["customers"][""], "customers#index")
        expect.equal(Routes["GET"]["customers"]["new"], "customers#new")
        expect.equal(Routes["GET"]["customers"]["refresh"], "customers#refresh")
        expect.equal(Routes["GET"]["customers"][":var"][""], "customers#show")
        expect.equal(Routes["GET"]["customers"][":var"]["ban"], "customers#ban")
        expect.equal(Routes["GET"]["customers"][":var"][":name"], "customer_id")
        expect.equal(Routes["GET"]["customers"][":var"]["edit"], "customers#edit")
        expect.equal(Routes["POST"]["customers"][""], "customers#create")
        expect.equal(Routes["DELETE"]["customers"][":var"][""], "customers#delete")

        expect.equal(Routes["GET"]["customers"][":var"]["comments"][""], "comments#index")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"]["new"], "comments#new")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"][""], "comments#show")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"][":name"], "comment_id")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["edit"], "comments#edit")
        expect.equal(Routes["POST"]["customers"][":var"]["comments"][""], "comments#create")
        expect.equal(Routes["DELETE"]["customers"][":var"]["comments"][":var"][""], "comments#delete")

        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["likes"][""], "likes#index")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["likes"]["new"], "likes#new")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["likes"][":var"][""], "likes#show")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["likes"][":var"][":name"], "like_id")
        expect.equal(Routes["GET"]["customers"][":var"]["comments"][":var"]["likes"][":var"]["edit"], "likes#edit")
        expect.equal(Routes["POST"]["customers"][":var"]["comments"][":var"]["likes"][""], "likes#create")
        expect.equal(Routes["DELETE"]["customers"][":var"]["comments"][":var"]["likes"][":var"][""], "likes#delete")

        expect.equal(Routes["POST"]["ban"], "customers#ban")

        expect.equal(Routes["GET"]["books"][""], "books#index")
        expect.equal(Routes["GET"]["books"][":var"][""], nil)
      end)
    end)
  end
}
