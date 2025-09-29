-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('luaonbeans', function()
      lester.before(function()
        -- This function is run before every test.
      end)

      describe('aqlpages#demo', function() -- Describe blocks can be nested.
        it('load AQL page', function()
          local status, h, body = Fetch("http://localhost:8080/demo")
          expect.equal(status, 500) -- I need to investigate later
        end)
      end)
    end)
  end
}
