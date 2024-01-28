-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('luaonbeans', function()
      lester.before(function()
        -- This function is run before every test.
      end)

      describe('welcome#index', function()       -- Describe blocks can be nested.
        it('load page', function()
          local status, h, body = Fetch("http://localhost:8080")
          expect.equal(status, 200)
          expect.truthy(string.match(body, "welcome"))
        end)
      end)
    end)
  end
}
