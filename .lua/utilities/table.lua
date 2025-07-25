-- Tables

table.keys = function(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end

table.contains = function(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

table.merge = function(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
	return t1
end

table.append = function(t1, t2)
	for _, v in ipairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

table.reject = function(t, key)
	local result = {}
	for k, v in pairs(t) do
		if k ~= key then
			result[k] = v
		end
	end
	return result
end

table.dig = function(t, keys)
	local current = t

	for _, key in ipairs(keys) do
		if type(current) == "table" and current[key] ~= nil then
			current = current[key]
		else
			return nil
		end
	end

	return current
end
