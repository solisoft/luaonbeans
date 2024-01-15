-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('utilities', function()
      lester.before(function()
        -- This function is run before every test.
      end)

      it('table.keys', function()
        local tab = { test = "demo" }
        local keys = table.keys(tab)
        expect.equal(keys, { "test" })
        expect.equal(#keys, 1)
      end)

      it('table.append', function()
        local tab = { "test" }
        tab = table.append(tab, { "demo" })
        expect.equal(tab, { "test", "demo" })
        expect.equal(#tab, 2)
      end)

      it('table.contains', function()
        expect.truthy(table.contains({ "demo" }, "demo"))
        expect.falsy(table.contains({ "demo2" }, "demo"))
      end)

      it('table.merge', function()
        local merged_table = table.merge(
          { demo = "test" },
          { test = "demo" }
        )
        expect.equal(merged_table, { demo = "test", test = "demo" })
      end)

      it('string.split', function()
        expect.equal(#string.split("Hello;world", ";"), 2)
        expect.equal(#string.split("Hello;world;:)", ";"), 3)
      end)

      it('string.to_slug', function()
        expect.equal(string.to_slug("Hello World!!!"), "hello-world")
        expect.equal(string.to_slug("Hello  %  World"), "hello-world")
      end)

      it('Pluralize', function()
        expect.equal(Pluralize("Bean"), "Beans")
        expect.equal(Pluralize("Entry"), "Entries")
        expect.equal(Pluralize("Potato"), "Potatoes")
        expect.equal(Pluralize("Table"), "Tables")
      end)

      it('Singularize', function()
        expect.equal(Singularize("Chess"), "Chess")
        expect.equal(Singularize("Beans"), "Bean")
        expect.equal(Singularize("Bean"), "Bean")
        expect.equal(Singularize("Entries"), "Entry")
        expect.equal(Singularize("Entry"), "Entry")
        expect.equal(Singularize("Potatoes"), "Potato")
        expect.equal(Singularize("Potato"), "Potato")
        expect.equal(Singularize("Tables"), "Table")
        expect.equal(Singularize("Table"), "Table")
        expect.equal(Singularize("Comments"), "Comment")
        expect.equal(Singularize("Comment"), "Comment")
      end)

      it('Capitalize', function()
        expect.equal(Capitalize("beans"), "Beans")
        expect.equal(Capitalize("lua on beans"), "Lua on beans")
      end)

      it('Camelize', function()
        expect.equal(Camelize("hello world"), "HelloWorld")
        expect.equal(Camelize("hello_world"), "HelloWorld")
      end)
    end)

  end
}