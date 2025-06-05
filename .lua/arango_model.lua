ArangoModel = {}
ArangoModel = setmetatable({}, { __index = ArangoModel })

function ArangoModel.new(data)
	local self = setmetatable({}, ArangoModel)
	self.filters = {}
	self.bindvars = {}
	self.sort = "doc._id ASC"
	self.data = data
	self.var_index = 0
	self.global_callbacks = {
		before_create = { "run_before_create_callback" },
		after_create = {},
		before_update = { "run_before_update_callback"	},
		after_update = {}
	}
	self.callbacks = { before_create = {}, before_update = {}, after_create = {}, after_update = {} }
	self.errors = {}
	self.validations = {}
	return self
end

function ArangoModel.run_before_create_callback(data)
	data.c_at = math.floor(GetTime() * 1000)
	data.u_at = math.floor(GetTime() * 1000)
	return data
end

function ArangoModel.run_before_update_callback(data)
	data.u_at = math.floor(GetTime() * 1000)
	return data
end

function ArangoModel:first()
	self:all({ per_page = 1 })
	self.data = self.data[1]
	return self
end

function ArangoModel:last()
	self.sort = "doc._id DESC"
	self:all({ per_page = 1 })
	self.data = self.data[1]
	return self
end

function ArangoModel:any()
	self.sort = "RAND()"
	self:first()
	return self
end

function ArangoModel:all(options)
	options = options or {}
	options.per_page = options.per_page or 30
	options.page = options.page or 1
	options.collection = options.collection or self.COLLECTION

	local offset = options.per_page * (options.page - 1)

	self.data = Adb.primary:Aql(
		[[
			FOR doc IN @@collection
		]] .. table.concat(self.filters) .. [[
			SORT ]] .. self.sort .. [[
			LIMIT @offset, @per_page
			RETURN doc
		]],
		table.merge({
			["@collection"] = options.collection,
			["per_page"] = options.per_page,
			["offset"] = offset
		}, self.bindvars)
	).result
	return self
end

function ArangoModel:find(handler)
	assert(self.data == nil, "find not allowed here")
	self.data = Adb.primary:GetDocument(handler)
	return self
end

function ArangoModel:find_by(criteria)
	self:where(criteria)
	self:first()
	return self
end

-- filtering

function ArangoModel:where(criteria)
	assert(criteria, "you must specify criteria")
	assert(type(criteria) == "table", "criteria must be a table")

	for k, v in pairs(criteria) do
		self.var_index = self.var_index + 1
		local var_name = "@data_%s" % { self.var_index }
		local bindvar_name = "data_%s" % { self.var_index }

		local filter = ""
		filter = " FILTER doc.%s == %s" % { k, var_name }
		self.bindvars = table.merge(self.bindvars, { [bindvar_name] = v })

		if type(v) == "table" then
			filter = " FILTER doc.%s IN %s" % { k, var_name }
			self.bindvars = table.merge(self.bindvars, { [bindvar_name] = v })
		end

		self.filters = table.append(self.filters, { filter })
	end

	return self
end

function ArangoModel:where_not(criteria)
	assert(criteria, "you must specify criteria")
	assert(type(criteria) == "table", "criteria must be a table")

	for k, v in pairs(criteria) do
		self.var_index = self.var_index + 1
		local var_name = "@data_%s" % { self.var_index }
		local bindvar_name = "data_%s" % { self.var_index }

		local filter = ""
		filter = " FILTER doc.%s != %s" % { k, var_name }
		self.bindvars = table.merge(self.bindvars, { [bindvar_name] = v })

		if type(v) == "table" then
			filter = " FILTER doc.%s NOT IN %s" % { k, var_name }
			self.bindvars = table.merge(self.bindvars, { [bindvar_name] = v })
		end

		self.filters = table.append(self.filters, { filter })
	end

	return self
end

function ArangoModel:filter_by(criteria, sign)
	assert(criteria, "you must specify criteria")
	assert(type(criteria) == "table", "criteria must be a table")

	for k, v in pairs(criteria) do
		self.var_index = self.var_index + 1
		local var_name = "@data_%s" % { self.var_index }
		local bindvar_name = "data_%s" % { self.var_index }

		local filter = ""
		filter = " FILTER doc.%s %s %s" % { k, sign, var_name }
		self.bindvars = table.merge(self.bindvars, { [bindvar_name] = v })
		self.filters = table.append(self.filters, { filter })
	end

	return self
end

function ArangoModel:gt(criteria)
	return self:filter_by(criteria, ">")
end

function ArangoModel:lt(criteria)
	return self:filter_by(criteria, "<")
end

function ArangoModel:lte(criteria)
	return self:filter_by(criteria, "<=")
end

function ArangoModel:gte(criteria)
	return self:filter_by(criteria, ">=")
end

-- sorting

function ArangoModel:sort(sort)
	self.sort = sort
	return self
end

-- validations

function ArangoModel:validates_each(data)
	self.errors = {}
	for field, validations in pairs(self.validations) do
		local value = table.contains(table.keys(data), field) and data[field] or nil
		for k, v in pairs(validations) do
			if k == "presence" then
				local default_error = "must be present"
				if v == true then v = { message = default_error } end
				if v.message == nil then v.message = default_error end
				if value == nil then
					self.errors = table.append(self.errors, {{ field = field, message = v.message }})
				end
			end

			if k == "numericality" then
				if type(value) ~= "number" then
					if type(v) == "number" then v = { message = "must be a valid number" } end
					self.errors = table.append(self.errors, {{ field = field, message = v.message }})
				end

				if type(v) == "table" and v.only_integer ~= nil then
					if v.message == nil then v = { message = "must be a valid integer" } end
					if math.type(value) ~= "integer" then
						self.errors = table.append(self.errors, {{ field = field, message = v.message }})
					end
				end
			end

			if k == "length" then
				local default_error = "must contains %d characters"
				if type(v) == "number" then v = { eq = v, message = default_error % { v } } end

				if table.contains(table.keys(v), "eq") then
					if v.message == nil then v.message = default_error % { v } end
					if #value ~= v.eq then
						if v.message == nil then v.message = "must contains %d characters" % { v.eq } end
						self.errors = table.append(self.errors, {{ field = field, message = v.message }})
					end
				end

				if table.contains(table.keys(v), "between") then
					assert(type(v["between"]) == "table", "'between' argument must be a table of 2 arguments")
					assert(#v["between"] == 2, "'between' argument must be a table of 2 arguments")
					assert(type(v["between"][1]) == "number" and type(v["between"][2]) == "number", "'between' arguments must be numbers")

					if #value < v["between"][1] or #value > v["between"][2] then
						if v.message == nil then v.message = "must be a value between %d and %d characters" % { v["between"][1], v["between"][2] } end
						self.errors = table.append(self.errors, {{ field = field, message = v.message }})
					end
				end

				if table.contains(table.keys(v), "minimum") then
					assert(type(v.minimum) == "number", "'minimum' argument must be a number")
					if #value < v.minimum then
						if v.message == nil then v.message = "must contains at least %d characters" % { v.minimum }	end
						self.errors = table.append(self.errors, {{ field = field, message = v.message }})
					end
				end

				if table.contains(table.keys(v), "maximum") then
					assert(type(v.maximum) == "number", "'maximum' argument must be a number")
					if #value > v.maximum then
						if v.message == nil then v.message = "must contains at max %d characters" % { v.maximum } end
						self.errors = table.append(self.errors, {{ field = field, message = v.message }})
					end
				end
			end

			if k == "format" then
				local default_error = "do not match the format"
				if type(v) == "string" then v = { re = v } end
				if v.message == nil then v.message = default_error end
				local regex = assert(re.compile(v.re))
				local match = regex:search(value)
				if match == nil then
					self.errors = table.append(self.errors, {{ field = field, message = default_error }})
				end
			end

			if k == "comparaison" then
				local default_error = "do not match value"
				if type(v) == "string" then v = { eq = v } end
				if v.message == nil then v.message = default_error end

				if v.eq then
					if self.data then
						if not table.contains(table.keys(self.data), v.eq) and table.contains(table.keys(data), v.eq) then
							self.data[v.eq] = data[v.eq]
						else
							if not table.contains(table.keys(self.data), v.eq) then self.data[v.eq] = nil end
						end
					end
					local against_data = self.data and self.data[v.eq] or data[v.eq]

					if data[field] ~= against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end

				if v.gt then
					if self.data then
						if not table.contains(table.keys(self.data), v.gt) and table.contains(table.keys(data), v.gt) then
							self.data[v.gt] = data[v.gt]
						else
							if not table.contains(table.keys(self.data), v.gt) then self.data[v.gt] = nil end
						end
					end
					local against_data = self.data and self.data[v.gt] or data[v.gt]

					if data[field] <= against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end

				if v.gte then
					if self.data then
						if not table.contains(table.keys(self.data), v.gte) and table.contains(table.keys(data), v.gte) then
							self.data[v.gte] = data[v.gte]
						else
							if not table.contains(table.keys(self.data), v.gte) then self.data[v.gte] = nil end
						end
					end
					local against_data = self.data and self.data[v.gte] or data[v.gte]

					if data[field] < against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end

				if v.lt then
					if self.data then
						if not table.contains(table.keys(self.data), v.lt) and table.contains(table.keys(data), v.lt) then
							self.data[v.lt] = data[v.lt]
						else
							if not table.contains(table.keys(self.data), v.lt) then self.data[v.lt] = nil end
						end
					end
					local against_data = self.data and self.data[v.lt] or data[v.lt]

					if data[field] >= against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end

				if v.lte then
					if self.data then
						if not table.contains(table.keys(self.data), v.lte) and table.contains(table.keys(data), v.lte) then
							self.data[v.lte] = data[v.lte]
						else
							if not table.contains(table.keys(self.data), v.lte) then self.data[v.lte] = nil end
						end
					end
					local against_data = self.data and self.data[v.lte] or data[v.lte]

					if data[field] > against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end

				if v.other_than then
					if self.data then
						if not table.contains(table.keys(self.data), v.other_than) and table.contains(table.keys(data), v.other_than) then
							self.data[v.other_than] = data[v.other_than]
						else
							if not table.contains(table.keys(self.data), v.other_than) then self.data[v.other_than] = nil end
						end
					end
					local against_data = self.data and self.data[v.other_than] or data[v.other_than]

					if data[field] == against_data then
						self.errors = table.append(self.errors, {{ field = field, message = default_error }})
					end
				end
			end

			if k == "acceptance" then
				local default_error = "you must accept"
				if(type(v) ~= "table") then v = { } end
				if v.message == nil then v.message = default_error end
				if value ~= true then
					self.errors = table.append(self.errors, {{ field = field, message = default_error }})
				end
			end

			if k == "inclusion" then
				local default_error = "must be part of the defined list"
				if v.message == nil then v.message = default_error end
				if table.contains(v.values, value) ~= true then
					self.errors = table.append(self.errors, {{ field = field, message = default_error }})
				end
			end

			if k == "exclusion" then
				local default_error = "must not be part of the defined list"
				if v.message == nil then v.message = default_error end
				if table.contains(v.values, value) ~= false then
					self.errors = table.append(self.errors, {{ field = field, message = default_error }})
				end
			end
		end
	end
end

-- collection

function ArangoModel:create(data)
	assert(self.data == nil, "create not allowed here")
	local callbacks = table.append(self.global_callbacks.before_create, self.callbacks.before_create)

	for _, methodName in pairs(callbacks) do data = self[methodName](data) end

	self:validates_each(data)

	if #self.errors == 0 then
		self.data = Adb.primary:CreateDocument(self.COLLECTION, data, "returnNew=true")["new"]
		local callbacks = table.append(self.global_callbacks.after_create, self.callbacks.after_create)
	  for _, methodName in pairs(callbacks) do self[methodName](self)	end
	end
	return self
end

function ArangoModel:update(data)
	assert(self.data, "udpate not allowed here")
	local callbacks = table.append(self.global_callbacks.before_update, self.callbacks.before_update)
	for _, methodName in pairs(callbacks) do data = self[methodName](data) end

	self:validates_each(data)

	if #self.errors == 0 then
		self.data = Adb.primary:UpdateDocument(self.data["_id"], data, "returnNew=true")["new"]
		local callbacks = table.append(self.global_callbacks.after_update, self.callbacks.after_update)
		for _, method in pairs(callbacks) do self[methodName](self)	end
	end
	return self
end

function ArangoModel:delete()
	assert(self.data, "delete not allowed here")
	local result = Adb.primary:DeleteDocument(self.data["_id"])
	self.data = nil
	return result
end

return ArangoModel
