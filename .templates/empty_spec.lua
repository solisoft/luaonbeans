-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('truthy test', function()
      it('pass the test', function()
        expect.truthy(true)
      end)
    end)
  end
}
