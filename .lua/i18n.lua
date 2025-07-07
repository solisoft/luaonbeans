local I18nClass = {}

-- Define methods before setting metatable
function I18nClass.new(locale, locales)
		local self = setmetatable({}, { __index = I18nClass })
		self.default_locale = locale or "en"
		self.locale = locale or "en"
		self.locales = locales or { "en" }
		self.translations = loadLocales()
		assert(self.t, "Error: I18nClass:t method is nil") -- Debug check
		return self
end

function I18nClass:t(path, params)
		params = type(params) == "table" and params or {}
		if type(path) ~= "string" or path == "" then
				return nil
		end

		local keys = string.split(path, ".")
		table.insert(keys, 1, self.locale)
		local str = table.dig(self.translations, keys)
		if not str then
			return nil
		end

		if type(str) == "string" then
			return params[1] and str % params or str
		end

		local count = tonumber(params[1]) or 0
		local key = count == 0 and "zero" or count == 1 and "one" or "more"
		local plural_str = str[key]
		return plural_str and type(plural_str) == "string" and plural_str % params or nil
end

-- Set metatable after defining methods
I18nClass = setmetatable(I18nClass, { __index = I18nClass })

-- Load locale files
function loadLocales(path, obj)
	path = path or "config/locales"
	obj = obj or {}
	local dir = unix.opendir(path)
	assert(dir, "Error opening path: " .. path)

	while true do
			local file, kind = dir:read()
			if not file then break end

			if kind == unix.DT_DIR and file ~= "." and file ~= ".." then
					local sub_obj = loadLocales(path .. "/" .. file, {})
					obj = table.merge(obj, sub_obj) -- Merge subdirectory translations
			elseif kind == unix.DT_REG and string.match(file, "%.lua$") then
					local file_path = (path .. "/" .. file:gsub("%.lua$", "")):gsub("^config/", ""):gsub("/", ".")
					local ok, locale_file = pcall(require, file_path)
					if ok and type(locale_file) == "table" then
							obj = table.merge(obj, locale_file)
					else
							print("Warning: Failed to load locale file: " .. file_path)
					end
			end
	end
	dir:close()
	return obj
end

-- Return the class for instantiation
return I18nClass
