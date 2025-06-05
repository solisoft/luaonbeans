local model = require("arango_model")
local Customer = setmetatable({}, { __index = model })
Customer.__index = Customer
Customer.COLLECTION = "customers"

return {
	run = function()
		describe('model validations', function()
			lester.after(function()
				Adb.primary:CreateCollection("customers")
				Adb.primary:DeleteCollection("customers")
			end)

			describe('presence', function()
				it('validates presence', function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = { demo = {	presence = { message = "must be present" } } }
						return self
					end

					local customer = Customer.new():create({ demo = true })
					expect.truthy(#customer.errors == 0)
					local customer = Customer.new():create({ demo2 = true })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].field, "demo")
					expect.equal(customer.errors[1].message, "must be present")
				end)
			end)

			describe("numericality", function()
				it("validates numericality (number)", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								numericality = { message = "must be a number" }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = 12.3 })
					expect.truthy(#customer.errors == 0)
				end)

				it("validates numericality (integer)", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								numericality = { message = "must be an integer", only_integer = true }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = 12.3 })
					expect.truthy(#customer.errors == 1)
					customer = Customer.new():create({ demo = 12 })
					expect.truthy(#customer.errors == 0)
				end)
			end)

			describe("length", function()
				it("validates a fixed length", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								length = 10
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456789" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456789A" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must contains 10 characters")
				end)

				it("validates a fixed length with 'is' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								length = { eq = 10, message = "yeah man" }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456789" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456789A" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "yeah man")
				end)

				it("validates a minimum length", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								length = { minimum = 10 }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456789" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "012345678" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must contains at least 10 characters")
				end)

				it("validates a maximum length", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								length = { maximum = 10 }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456789" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456789A" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must contains at max 10 characters")
				end)

				it("validates 'between' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								length = { between = { 10, 12 } }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456789" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456789ACDEF" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must be a value between 10 and 12 characters")

					customer = Customer.new():create({ demo = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must be a value between 10 and 12 characters")
				end)

			end)

			describe("format", function()
					it("validates the format", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								format = [[^\d+$]]
							}
						}
						return self
					end

					customer = Customer.new():create({ demo = "012345" })
					expect.truthy(#customer.errors == 0)
					customer = Customer.new():create({ demo = "012345abcd" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match the format")
				end)

			end)

			describe("comparaison", function()
				it("validates comparaison using the field name", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = "demo2"
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "012345", demo2 = "0123456" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")
				end)

				it("validates comparaison using the 'gt' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = { gt = "demo2"	 }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "012345", demo2 = "0123456" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")

					customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")
				end)

				it("validates comparaison using the 'gte' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = { gte = "demo2" 	}
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "0123456", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "012345", demo2 = "0123456" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")

					customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)
				end)

				it("validates comparaison using the 'lt' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = { lt = "demo2" 	}
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "01234", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456", demo2 = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")

					customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")
				end)

				it("validates comparaison using the 'lte' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = { lte = "demo2" 	}
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "01234", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456", demo2 = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")

					customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)
				end)

				it("validates comparaison using the 'other_than' attribute", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								comparaison = { other_than = "demo2" 	}
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "01234", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "0123456", demo2 = "012345" })
					expect.truthy(#customer.errors == 0)

					customer = Customer.new():create({ demo = "012345", demo2 = "012345" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "do not match value")
				end)
			end)

			describe("acceptance", function()
			  it("validates acceptance", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = { acceptance = true }
						}
						return self
					end

					local customer = Customer.new():create({ demo = true })
					expect.truthy(#customer.errors == 0)

					local customer = Customer.new():create({ demo = false })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "you must accept")
				end)
			end)

			describe("inclusion", function()
				it("validates inclusion", function()
					function Customer.new(data)
						local self = setmetatable(model.new(data), Customer)
						self.validations = {
							demo = {
								inclusion = { values = { "red", "green", "blue" } }
							}
						}
						return self
					end

					local customer = Customer.new():create({ demo = "red" })
					expect.truthy(#customer.errors == 0)

					local customer = Customer.new():create({ demo = "orange" })
					expect.truthy(#customer.errors == 1)
					expect.equal(customer.errors[1].message, "must be part of the defined list")
				end)
			end)

			describe("exclusion", function()
				it("validates exclusion", function()
						function Customer.new(data)
							local self = setmetatable(model.new(data), Customer)
							self.validations = {
								demo = {
									exclusion = { values = { "red", "green", "blue" } }
								}
							}
							return self
						end

						local customer = Customer.new():create({ demo = "orange" })
						expect.truthy(#customer.errors == 0)

						local customer = Customer.new():create({ demo = "red" })
						expect.truthy(#customer.errors == 1)
						expect.equal(customer.errors[1].message, "must not be part of the defined list")
					end)
			end)
		end)
	end
}
