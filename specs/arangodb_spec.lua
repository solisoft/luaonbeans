-- Lester documentation : https://edubart.github.io/lester/

return {
  run = function()
    describe('arangodb driver', function()
      lester.before(function()
        -- This function is run before every test.
      end)

      -- AQL

      describe('Aql', function()
        it('run request', function()
          local uuid = adb.Aql("RETURN UUID()").result[1]
          expect.truthy(#uuid == 36)
        end)

        it('fail running request', function()
          local req = adb.Aql("RETURN UUID2()")
          expect.truthy(req.error == true)
          expect.truthy(req.code == 400)
        end)
      end)

      -- DOCUMENTS

      describe('CreateDocument', function()
        it('create document', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local doc = adb.CreateDocument("test_data", { demo = true })
          expect.truthy(type(doc._key) == "string")
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      describe('GetDocument', function()
        it('get document', function()
          local collection = adb.CreateCollection("demo")
          expect.truthy(collection.code == 200)
          local doc = adb.CreateDocument("demo", { demo = true })
          expect.truthy(type(doc._key) == "string")
          doc = adb.GetDocument(doc._id)
          expect.truthy(type(doc._key) == "string")
          expect.truthy(doc.demo == true)
          collection = adb.DeleteCollection("demo")
          expect.truthy(collection.code == 200)
        end)
      end)

      describe('UpdateDocument', function()
        it('update document', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local doc = adb.CreateDocument("test_data", { demo = true })
          expect.truthy(type(doc._key) == "string")
          local updated_doc = adb.UpdateDocument(doc._id, { modified_at = "now" })
          expect.equal(doc._id, updated_doc._id)
          local read_doc = adb.GetDocument(doc._id)
          expect.equal(read_doc.modified_at, "now")
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      describe('DeleteDocument', function()
        it('delete document', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local doc = adb.CreateDocument("test_data", { demo = true })
          expect.truthy(type(doc._key) == "string")
          doc = adb.DeleteDocument(doc._id)
          expect.truthy(collection.code == 200)
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      -- COLLECTIONS

      describe('UpdateCollection', function()
        local collection = adb.CreateCollection("test_data")
        expect.truthy(collection.code == 200)

        collection = adb.UpdateCollection("test_data", {
          schema = {
            message = "The document does not contain an array of numbers in attribute 'nums', or one of the numbers is greater than 6.",
            level = "moderate",
            type = "json",
            rule = {
              properties = {
                nums = {
                  type = "array",
                  items = {
                      type = "number",
                      maximum = 6
                  }
                }
              },
              additionalProperties = {
                  type = "string"
              },
              required = { "nums" }
            }
          }
        })
        expect.truthy(#table.keys(collection.schema) > 0)
        collection = adb.DeleteCollection("test_data")
        expect.truthy(collection.code == 200)
      end)

      describe('RenameCollection', function()
        local collection = adb.CreateCollection("test_data")
        expect.truthy(collection.code == 200)

        collection = adb.RenameCollection("test_data", { name = "test_data2" })
        expect.truthy(collection.code == 200)

        collection = adb.DeleteCollection("test_data2")
        expect.truthy(collection.code == 200)
      end)

      describe('Create and delete Collection', function()
        it('create and delete collection', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      -- INDEXES

      describe('GetAllIndexes', function()
        it('get all indexes', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local indexes = adb.GetAllIndexes("test_data")
          expect.truthy(indexes.code == 200)
          expect.equal(#table.keys(indexes.identifiers), 1)
          local index = adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
          expect.truthy(index.code == 201)
          indexes = adb.GetAllIndexes("test_data")
          expect.truthy(indexes.code == 200)
          expect.equal(#table.keys(indexes.identifiers), 2)
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      describe('CreateIndex', function()
        it('create index', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local index = adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
          expect.truthy(index.code == 201)
          expect.equal(index.fields, { "filename" })
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      describe('DeleteIndex', function()
        it('delete index', function()
          local collection = adb.CreateCollection("test_data")
          expect.truthy(collection.code == 200)
          local index = adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
          expect.truthy(index.code == 201)
          expect.equal(index.fields, { "filename" })
          local indexes = adb.GetAllIndexes("test_data")
          expect.truthy(indexes.code == 200)
          expect.equal(#table.keys(indexes.identifiers), 2)
          local req = adb.DeleteIndex(index.id)
          indexes = adb.GetAllIndexes("test_data")
          expect.truthy(indexes.code == 200)
          expect.equal(#table.keys(indexes.identifiers), 1)
          collection = adb.DeleteCollection("test_data")
          expect.truthy(collection.code == 200)
        end)
      end)

      -- DATABASE

      describe('Create and Delete Database', function()
        it('create and delete database', function()
          assert(adb.Auth(db_config["system"]) ~= null)
          local database = adb.CreateDatabase('luaonbean_1234_spec')
          expect.equal(database.code, 201)
          database = adb.DeleteDatabase('luaonbean_1234_spec')
          expect.equal(database.code, 200)
          assert(adb.Auth(db_config[beans_env]) ~= null)
        end)
      end)

      -- TRANSACTIONS

      describe('Transactions', function()

      end, false)

      -- CACHE

      describe('GetQueryCacheEntries', function()
        it('get query cache', function()

        end, false)
      end)

      describe('GetQueryCacheConfiguration', function()
        it('get query cache configuration', function()

        end, false)
      end)

      describe('UpdateCacheConfiguration', function()
        it('update query cache configuration', function()

        end, false)
      end)

      describe('DeleteQueryCache', function()
        it('delete query cache configuration', function()

        end, false)
      end)

      describe('RefreshToken', function()
        it('refresh auth token', function()

        end, false)
      end)
    end)
  end
}