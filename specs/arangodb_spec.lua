-- Lester documentation : https://edubart.github.io/lester/

return {
	run = function()
		describe("arangodb driver", function()
			lester.after(function()
				Adb.primary:CreateCollection("test_data")
				Adb.primary:DeleteCollection("test_data")
			end)

			-- AQL

			describe("Aql", function()
				it("run request", function()
					local uuid = Adb.primary:Aql("RETURN UUID()").result[1]
					expect.truthy(#uuid == 36)
				end)

				it("fail running request", function()
					local req = Adb.primary:Aql("RETURN UUID2()")
					expect.truthy(req.error == true)
					expect.truthy(req.code == 400)
				end)
			end)

			-- DOCUMENTS

			describe("CreateDocument", function()
				it("create document", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)

					local doc = Adb.primary:CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("GetDocument", function()
				it("get document", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.primary:CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					doc = Adb.primary:GetDocument(doc._id)
					expect.truthy(type(doc._key) == "string")
					expect.truthy(doc.demo == true)
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("UpdateDocument", function()
				it("update document", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.primary:CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					local updated_doc = Adb.primary:UpdateDocument(doc._id, { modified_at = "now" })
					expect.equal(doc._id, updated_doc._id)
					local read_doc = Adb.primary:GetDocument(doc._id)
					expect.equal(read_doc.modified_at, "now")
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("DeleteDocument", function()
				it("delete document", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local doc = Adb.primary:CreateDocument("test_data", { demo = true })
					expect.truthy(type(doc._key) == "string")
					doc = Adb.primary:DeleteDocument(doc._id)
					expect.truthy(collection.code == 200)
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- COLLECTIONS

			describe("UpdateCollection", function()
				it("update a collection", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)

					collection = Adb.primary:UpdateCollection("test_data", {
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
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("RenameCollection", function()
				it("rename a collection", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)

					collection = Adb.primary:RenameCollection("test_data", { name = "test_data2" })
					expect.truthy(collection.code == 200)

					collection = Adb.primary:DeleteCollection("test_data2")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("Create and delete Collection", function()
				it("create and delete collection", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- INDEXES

			describe("GetAllIndexes", function()
				it("get all indexes", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local indexes = Adb.primary:GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 1)
					local index =
						Adb.primary:CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					indexes = Adb.primary:GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 2)
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("CreateIndex", function()
				it("create index", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local index =
						Adb.primary:CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					expect.equal(index.fields, { "filename" })
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			describe("DeleteIndex", function()
				it("delete index", function()
					local collection = Adb.primary:CreateCollection("test_data")
					expect.truthy(collection.code == 200)
					local index =
						Adb.primary:CreateIndex("test_data", { type = "persistent", unique = true, fields = { "filename" } })
					expect.truthy(index.code == 201)
					expect.equal(index.fields, { "filename" })
					local indexes = Adb.primary:GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 2)
					local req = Adb.primary:DeleteIndex(index.id)
					indexes = Adb.primary:GetAllIndexes("test_data")
					expect.truthy(indexes.code == 200)
					expect.equal(#table.keys(indexes.identifiers), 1)
					collection = Adb.primary:DeleteCollection("test_data")
					expect.truthy(collection.code == 200)
				end)
			end)

			-- DATABASE

			describe("Create and Delete Database", function()
				it("create and delete database", function()
					local database = Adb.system:CreateDatabase("luaonbean_1234_spec")
					expect.equal(database.code, 201)
					database = Adb.system:DeleteDatabase("luaonbean_1234_spec")
					expect.equal(database.code, 200)
				end)
			end)

			-- STREAM TRANSACTIONS

			describe("Stream Transactions", function()
				it("create and commit a transaction", function()
					local transaction = Adb.primary:BeginTransaction({ collections = {} })
					expect.equal(transaction.code, 201)
					transaction = Adb.primary:CommitTransaction(transaction.result.id)
					expect.equal(transaction.code, 200)
				end)

				it("create and abort a transaction", function()
					local transaction = Adb.primary:BeginTransaction({ collections = {} })
					expect.equal(transaction.code, 201)
					transaction = Adb.primary:AbortTransaction(transaction.result.id)
					expect.equal(transaction.code, 200)
				end)
			end)

			-- JAVASCRIPT TRANSACTIONS

			describe("Javascript Transactions", function()
				it("execute a transaction", function()
					Adb.primary:CreateCollection("test_data")
					local transaction = Adb.primary:Transaction(
						{
							collections = { read = "test_data" },
							action = [[
								function() {
									console.log("hello js transactions")
								}
							]]
						}
					)
					expect.equal(transaction.code, 200)
				end)

				it("do not execute a transaction", function()
					Adb.primary:CreateCollection("test_data")
					local transaction = Adb.primary:Transaction(
						{
							collections = { },
							action = [[
									console.log("hello js transactions")
							]]
						}
					)
					expect.equal(transaction.code, 400)
				end)

				it("do not execute a transaction", function()
					Adb.primary:CreateCollection("test_data")
					local transaction = Adb.primary:Transaction(
						{
							collections = { },
							action = [[
								function() {
									throw("error js transactions")
								}
							]]
						}
					)
					expect.equal(transaction.code, 500)
					expect.equal(transaction.errorMessage, "error js transactions")
				end)
			end)

			-- UDF

			describe("User Defined Functions", function()
				it("create / read / delete a function", function()
					local fn = Adb.primary:CreateFunction({
						name = "myfunctions::temperature::celsiustofahrenheit",
						code = "function (celsius) { return celsius * 1.8 + 32; }"
					})
					expect.equal(fn.code, 201)

					local fns = Adb.primary:ListFunctions()
					expect.equal(fns.code, 200)
					expect.equal(#fns.result, 1)
					expect.equal(fns.result[1].name, "myfunctions::temperature::celsiustofahrenheit")

					local dfn = Adb.primary:DeleteFunction(
						"myfunctions::temperature::celsiustofahrenheit"
					)
					expect.equal(dfn.code, 200)

					fns = Adb.primary:ListFunctions()
					expect.equal(fns.code, 200)
					expect.equal(#fns.result, 0)
				end)
			end)

			-- CACHE

			describe("GetQueryCacheEntries", function()
				it("get empty query cache", function()
					expect.equal(type(Adb.primary:GetQueryCacheEntries()), "table")
				end)
			end)

			describe("GetQueryCacheConfiguration", function()
				it("get query cache configuration", function()
					Adb.primary:UpdateCacheConfiguration({ mode = "off" })
					expect.equal(Adb.primary:GetQueryCacheConfiguration().mode, "off")
				end)
			end)

			describe("UpdateCacheConfiguration", function()
				it("update query cache configuration", function()
					Adb.primary:UpdateCacheConfiguration({ mode = "on" })
					expect.equal(Adb.primary:GetQueryCacheConfiguration().mode, "on")
				end)
			end)

			describe("DeleteQueryCache", function()
				it("delete query cache configuration", function()
					expect.equal(Adb.primary:DeleteQueryCache().code, 200)
				end)
			end)

			describe("RefreshToken", function()
				it("refresh auth token", function()
					last_db_connect = 1000
					assert(Adb.primary:RefreshToken() == nil)
				end)
			end)
		end)
	end,
}
