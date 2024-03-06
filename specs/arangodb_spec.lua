-- Lester documentation : https://edubart.github.io/lester/

return {
	run = function()
		describe("arangodb driver", function()
			lester.before(function()
				-- This function is run before every test.
			end)

			-- AQL

			describe("Aql", function()
				it("run request", function()
					local uuid = Adb.Aql("RETURN UUID()").result[1]
					expect.truthy(#uuid == 36)
				end)

				it("fail running request", function()
					local req = Adb.Aql("RETURN UUID2()")
					expect.truthy(req.error == true)
					expect.truthy(req.code == 400)
				end)
			end)

			-- DOCUMENTS

			describe("CreateDocument", function()
				it("create document", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("GetDocument", function()
				it("get document", function()
					local collection = Adb.CreateCollection("demo")
					expect.truthy(collection.code == 200)
					local doc = Adb.CreateDocument("demo", { demo = true })
					expect.truthy(type(doc._key) == "string")
					doc = Adb.GetDocument(doc._id)
					expect.truthy(type(doc._key) == "string")
					expect.truthy(doc.demo == true)
					collection = Adb.DeleteCollection("demo")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("UpdateDocument", function()
				it("update document", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					local updated_doc = Adb.UpdateDocument(doc._id, { modified_at = "now" })
					expect.equal(doc._id, updated_doc._id)
					local read_doc = Adb.GetDocument(doc._id)
					expect.equal(read_doc.modified_at, "now")
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("DeleteDocument", function()
				it("delete document", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					doc = Adb.DeleteDocument(doc._id)
					expect.truthy(collection.code == 200)
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- COLLECTIONS

			describe("UpdateCollection", function()
				it("update a collection", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)

					collection = Adb.UpdateCollection("test_data", {
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
											maximum = 6,
										},
									},
								},
								additionalProperties = {
									type = "string",
								},
								required = { "nums" },
							},
						},
					})
					expect.truthy(#table.keys(collection.schema) > 0)
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("RenameCollection", function()
				it("rename a collection", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)

					collection = Adb.RenameCollection("test_data", { name = "test_data2" })
					expect.truthy(collection.code == 200)

					collection = Adb.DeleteCollection("test_data2")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("Create and delete Collection", function()
				it("create and delete collection", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- INDEXES

			describe("GetAllIndexes", function()
				it("get all indexes", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local indexes = Adb.GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 1)
					local index =
						Adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					indexes = Adb.GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 2)
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("CreateIndex", function()
				it("create index", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local index =
						Adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					expect.equal(index.fields, { "filename" })
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("DeleteIndex", function()
				it("delete index", function()
					local collection = Adb.CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local index =
						Adb.CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					expect.equal(index.fields, { "filename" })
					local indexes = Adb.GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 2)
					local req = Adb.DeleteIndex(index.id)
					indexes = Adb.GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 1)
					collection = Adb.DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- DATABASE

			describe("Create and Delete Database", function()
				it("create and delete database", function()
					assert(Adb.Auth(DBConfig["system"]) ~= nil)
					local database = Adb.CreateDatabase("luaonbean_1234_spec")
					expect.equal(database.code, 201)
					database = Adb.DeleteDatabase("luaonbean_1234_spec")
					expect.equal(database.code, 200)
					assert(Adb.Auth(DBConfig["test"]) ~= nil)
				end)
			end)

			-- TRANSACTIONS

			describe("Transactions", function()
				it("create and commit a transaction", function()
					local transaction = Adb.BeginTransaction({ collections = {} })
					expect.equal(transaction.code, 201)
					transaction = Adb.CommitTransaction(transaction.result.id)
					expect.equal(transaction.code, 200)
				end)

				it("create and abort a transaction", function()
					local transaction = Adb.BeginTransaction({ collections = {} })
					expect.equal(transaction.code, 201)
					transaction = Adb.AbortTransaction(transaction.result.id)
					expect.equal(transaction.code, 200)
				end)
			end)

			-- CACHE

			describe("GetQueryCacheEntries", function()
				it("get empty query cache", function()
					expect.equal(type(Adb.GetQueryCacheEntries()), "table")
				end)
			end)

			describe("GetQueryCacheConfiguration", function()
				it("get query cache configuration", function()
					Adb.UpdateCacheConfiguration({ mode = "off" })
					expect.equal(Adb.GetQueryCacheConfiguration().mode, "off")
				end)
			end)

			describe("UpdateCacheConfiguration", function()
				it("update query cache configuration", function()
					Adb.UpdateCacheConfiguration({ mode = "on" })
					expect.equal(Adb.GetQueryCacheConfiguration().mode, "on")
				end)
			end)

			describe("DeleteQueryCache", function()
				it("delete query cache configuration", function()
					expect.equal(Adb.DeleteQueryCache().code, 200)
				end)
			end)

			describe("RefreshToken", function()
				it("refresh auth token", function()
					last_db_connect = 1000
					assert(Adb.RefreshToken(DBConfig["test"]) == nil)
				end)
			end)
		end)
	end,
}
