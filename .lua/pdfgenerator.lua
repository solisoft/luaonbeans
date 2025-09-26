-- PDF Generator Library for PDF 1.7
local PDFGenerator = {}

-- PDF object counter
local objCounter = 1

local function loadAsset(path)
	return LoadAsset(path) -- TODO: update for another framework (e.g. Lapis / openresty)
end

local function decodeJson(json)
	return DecodeJson(json) -- TODO: update for another framework (e.g. Lapis / openresty)
end

-- Utility function to get new object number
local function getNewObjNum()
	local num = objCounter
	objCounter = objCounter + 1
	return num
end

-- Create new PDF document
function PDFGenerator.new(options)
	objCounter = 1
	local self = {
		objects = {},
		current_page = 0,
		current_page_obj = nil,
		page_list = {}, -- Array to store page objects
		pages_obj = nil, -- Object number for pages tree
		images = {},
		contents = {},
		catalog = nil,
		info = nil,
		root = nil,
		page_width = 595,
		page_height = 842,
		header_height = 0,
		margin_x = { 50, 50 },
		margin_y = { 50, 80 },
		current_x = 0,
		current_y = 0,
		resources = {},
		font_metrics = {},
		fonts = {},
		rgb_colors = {},
		last_font = { fontFamily = "helvetica", fontWeight = "normal" },
		current_table = {
			current_row = {
				height = nil,
			},
			padding_x = 5,
			padding_y = 5,
			header_columns = nil,
			data_columns = nil,
			header_options = nil,
			data_options = nil,
		},
		out_of_page = false,
	}

	self = table.merge(self, options or {})

	self.header = function(pageId) end
	self.footer = function(pageId)
		self.moveY(self, 5)
		self:addParagraph("Page %s of %s" % { pageId, #self.page_list }, { fontSize = 8, alignment = "right" })
	end

	-- Initialize document
	self.info = getNewObjNum()
	self.root = getNewObjNum()
	self.pages_obj = getNewObjNum()
	self.basic_font_obj = getNewObjNum()
	self.basic_bold_font_obj = getNewObjNum()

	-- Initialize resources
	self.resources = { fonts = {}, images = {} }

	-- Add required PDF objects
	self.objects[self.info] = string.format(
		"%d 0 obj\n<< /Producer (Lua PDF Generator 1.0) /CreationDate (D:%s) >>\nendobj\n",
		self.info,
		os.date("!%Y%m%d%H%M%S")
	)

	return setmetatable(self, { __index = PDFGenerator })
end

function PDFGenerator:getHashValues(hash)
	local values = {}
	for _, value in pairs(hash) do
		table.insert(values, math.floor(value + 0.5))
	end
	return values
end

-- Convert number to PDF string format
local numCache = setmetatable({}, { __mode = "kv" })
local function numberToString(num)
	local cached = numCache[num]
	if cached then
		return cached
	end
	local s = "%.2f" % { num } -- redbean specific
	numCache[num] = s
	return s
end

-- Start a new page
function PDFGenerator:addPage(width, height)
	width = width or 595 -- Default A4 width in points
	height = height or 842 -- Default A4 height in points

	local pageObj = getNewObjNum()
	local contentObj = getNewObjNum()

	if self.current_page == 0 then
		self:addBasicFont()
	end

	-- Add page object to the list
	table.insert(self.page_list, pageObj)
	self.current_page_obj = pageObj
	self.current_page = self.current_page + 1

	-- Create content stream
	self.contents[pageObj] = { id = contentObj, streams = {} }

	-- Add page object definition
	self.objects[pageObj] = string.format(
		"%d 0 obj\n<< /Type /Page /Parent %d 0 R /Contents %d 0 R /MediaBox [0 0 %s %s] /Resources << /Font << /F1 %d 0 R /F2 %d 0 R >> /XObject << >> >> >>\nendobj\n",
		pageObj,
		self.pages_obj,
		contentObj,
		numberToString(width),
		numberToString(height),
		self.basic_font_obj,
		self.basic_bold_font_obj
	)

	-- Ensure all custom fonts are properly added to page resources
	for _, font in ipairs(self.fonts) do
		self:addFontToPageResources(font[1], font[2])
	end

	self:setY(0)
	self:setX(0)

	-- Display table header
	if self.current_table.header_columns then
		self:drawTableRow(self.current_table.header_columns, self.current_table.header_options)
	end

	return self
end

-- Add basic Helvetica font
function PDFGenerator:addBasicFont()
	self.objects[self.basic_font_obj] = string.format(
		"%d 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n",
		self.basic_font_obj
	)

	self.objects[self.basic_bold_font_obj] = string.format(
		"%d 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n",
		self.basic_bold_font_obj
	)

	self.custom_fonts = {
		["helvetica-normal"] = self.basic_bold_font_obj,
		["helvetica-bold"] = self.basic_bold_font_obj,
	}
end

-- Add custom font (TrueType)
function PDFGenerator:addCustomFont(fontPath, fontName, fontWeight)
	local fontObj = getNewObjNum()
	local fontFileObj = getNewObjNum()
	local fontDescObj = getNewObjNum()

	table.insert(self.fonts, { fontName, fontWeight })

	fullFontName = fontName .. "-" .. fontWeight

	-- Read font file
	local fontData = loadAsset(fontPath)
	local fontMetrics = loadAsset(fontPath:gsub("%.ttf$", ".json"))
	assert(fontMetrics, "You need the metrics json file")

	self.custom_fonts = self.custom_fonts or {}
	self.custom_fonts[fullFontName] = fontObj

	self.font_metrics[fullFontName] = decodeJson(fontMetrics)

	-- Improved font descriptor object with better Firefox compatibility
	self.objects[fontDescObj] = string.format(
		"%d 0 obj\n<< /Type /FontDescriptor /FontName /%s /Flags 32 /FontBBox [-250 -250 1250 1250] /ItalicAngle 0 /Ascent 750 /Descent -250 /CapHeight 750 /StemV 80 /StemH 80 /FontFile2 %d 0 R /FontFamily (%s) /FontStretch /Normal /FontWeight %s >>\nendobj\n",
		fontDescObj,
		fullFontName,
		fontFileObj,
		fontName,
		fontWeight == "bold" and "700" or "400"
	)

	-- Font file stream object with proper encoding
	-- Note: For TrueType fonts, we don't use FlateDecode as the font data is already compressed
	self.objects[fontFileObj] = string.format(
		"%d 0 obj\n<< /Length %d /Length1 %d >>\nstream\n%sendstream\nendobj\n",
		fontFileObj,
		#fontData,
		#fontData,
		fontData
	)

	-- Improved font object with better encoding support
	self.objects[fontObj] = string.format(
		"%d 0 obj\n<< /Type /Font /Subtype /TrueType /BaseFont /%s /FirstChar 32 /LastChar 255 /Widths [%s] /Encoding /WinAnsiEncoding /FontDescriptor %d 0 R /ToUnicode %d 0 R >>\nendobj\n",
		fontObj,
		fullFontName,
		self:generateWidthsArray(fullFontName),
		fontDescObj,
		self:createToUnicodeStream()
	)

	self:useFont(fontName, fontWeight)
end

-- Generate widths array for better font rendering
function PDFGenerator:generateWidthsArray(fontName)
	local widths = {}
	local fontMetrics = self.font_metrics[fontName]

	for i = 32, 255 do
		local width = fontMetrics["" .. i] or 556
		table.insert(widths, math.floor(width + 0.5))
	end

	return table.concat(widths, " ")
end

-- Create ToUnicode stream for better text extraction and rendering
function PDFGenerator:createToUnicodeStream()
	local toUnicodeObj = getNewObjNum()
	local toUnicodeContent =
		"/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n/CMapName /Adobe-Identity-UCS def\n/CMapType 2 def\n1 begincodespacerange\n<0020> <00FF>\nendcodespacerange\n"

	-- Add character mappings for basic Latin
	for i = 32, 255 do
		local hexCode = string.format("%04X", i)
		toUnicodeContent = toUnicodeContent .. string.format("<%s> <%s>\n", hexCode, hexCode)
	end

	toUnicodeContent = toUnicodeContent .. "endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend"

	self.objects[toUnicodeObj] = string.format(
		"%d 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n",
		toUnicodeObj,
		#toUnicodeContent,
		toUnicodeContent
	)

	return toUnicodeObj
end

-- Properly escape text for PDF content streams
function PDFGenerator:escapePdfText(text)
	if not text then
		return ""
	end

	-- Escape special PDF characters
	local escaped = text:gsub("\\", "\\\\")
	escaped = escaped:gsub("%(", "\\(")
	escaped = escaped:gsub("%)", "\\)")
	escaped = escaped:gsub("%[", "\\[")
	escaped = escaped:gsub("%]", "\\]")
	escaped = escaped:gsub("%{", "\\{")
	escaped = escaped:gsub("%}", "\\}")
	escaped = escaped:gsub("%%", "\\%")

	-- Handle non-ASCII characters by converting to octal
	local result = {}
	for i = 1, #escaped do
		local byte = string.byte(escaped, i)
		if byte >= 32 and byte <= 126 then
			table.insert(result, string.char(byte))
		else
			table.insert(result, string.format("\\%03o", byte))
		end
	end

	return table.concat(result)
end

-- Use custom font for text
function PDFGenerator:useFont(fontName, fontWeight)
	fontWeight = fontWeight or "normal"
	self.last_font = self.last_font or {}
	self.last_font.fontFamily = fontName
	self.last_font.fontWeight = fontWeight

	-- Store the current font name to be used in addText
	self.current_font = fontName

	-- Ensure font is added to current page resources
	self:addFontToPageResources(fontName, fontWeight)

	return self
end

-- Add font to page resources for better cross-browser compatibility
function PDFGenerator:addFontToPageResources(fontName, fontWeight)
	fontWeight = fontWeight or "normal"
	local fullFontName = fontName .. "-" .. fontWeight

	if not self.custom_fonts or not self.custom_fonts[fullFontName] then
		return -- Font not loaded
	end

	local pageObj = self.current_page_obj
	local pageContent = self.objects[pageObj]

	-- Check if font is already in page resources
	if pageContent:find("/" .. fullFontName .. " %d+ 0 R") then
		return -- Font already added
	end

	-- Add font to page resources
	if pageContent:find("(/Font << [^>]+ >>)") then
		-- Append to existing font dictionary
		pageContent = pageContent:gsub("(/Font << [^>]+ >>)", function(fontDict)
			return string.format(
				"%s /%s %d 0 R",
				fontDict:sub(1, -3), -- Remove trailing ">>"
				fullFontName,
				self.custom_fonts[fullFontName]
			) .. " >>"
		end)
	else
		-- Create new font dictionary
		pageContent = pageContent:gsub(
			"(/Resources << )",
			string.format(
				"/Resources << /Font << /F1 %d 0 R /F2 %d 0 R /%s %d 0 R >> ",
				self.basic_font_obj,
				self.basic_bold_font_obj,
				fullFontName,
				self.custom_fonts[fullFontName]
			)
		)
	end

	self.objects[pageObj] = pageContent
end

-- Use custom font for text
function PDFGenerator:setFont(fontName)
	self.last_font = self.last_font or {}
	self.last_font.fontFamily = fontName

	-- Store the current font name to be used in addText
	self.current_font = fontName
end

-- Get text width for current font and size using font metrics
function PDFGenerator:getTextWidth(text, fontSize, fontWeight)
	fontSize = fontSize or 12
	fontWeight = fontWeight or "normal"

	self.font_metrics = self.font_metrics or {}
	local fontMetrics = self.font_metrics[self.last_font.fontFamily .. "-" .. fontWeight]

	if fontMetrics == nil then
		return
	end
	local width = 0
	for i = 1, #text do
		local charCode = string.byte(text, i)
		width = width + (fontMetrics["" .. charCode] or 556) -- default to 556 for unknown chars
	end

	-- Convert from font units (1/1000) to points
	return (width * fontSize) / 1000
end

-- Split text into lines based on page width
function PDFGenerator:splitTextToLines(text, fontSize, maxWidth)
	fontSize = fontSize or 12
	maxWidth = maxWidth or (self.page_width - self.margin_x[1] - self.margin_x[2])

	local lines = {}
	local words = {}

	-- Split text into words
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end

	local currentLine = ""
	local currentWidth = 0

	for i, word in ipairs(words) do
		local wordWidth = self:getTextWidth(word, fontSize, self.last_font.fontWeight)
		local spaceWidth = self:getTextWidth(" ", fontSize, self.last_font.fontWeight)

		-- Check if adding this word would exceed maxWidth
		if currentWidth + wordWidth + (currentWidth > 0 and spaceWidth or 0) <= maxWidth then
			-- Add space if not first word in line
			if currentWidth > 0 then
				currentLine = currentLine .. " "
				currentWidth = currentWidth + spaceWidth
			end
			-- Add word to current line
			currentLine = currentLine .. word
			currentWidth = currentWidth + wordWidth
		else
			-- Line would be too long, store current line and start new one
			if currentLine ~= "" then
				table.insert(lines, currentLine)
			end
			currentLine = word
			currentWidth = wordWidth
		end
	end

	-- Don't forget the last line
	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	return lines
end

-- Add text to current page
function PDFGenerator:addText(text, fontSize, color, alignment, width)
	width = width or self.page_width
	fontSize = fontSize or 12
	color = color or "000" -- default black
	alignment = alignment or "justify" -- default left alignment
	color = PDFGenerator:hexToRGB(color)

	local content = self.contents[self.current_page_obj]
	local fontName = self.last_font.fontWeight == "bold" and "F1" or "F2"

	if self.current_font then
		fontName = self.current_font .. "-" .. self.last_font.fontWeight
	end

	-- Calculate x position based on alignment
	local x_pos = self.margin_x[1] + self.current_x
	local text_width = self:getTextWidth(text, fontSize, self.last_font.fontWeight)

	if alignment == "center" then
		x_pos = x_pos + (width - text_width) / 2
	elseif alignment == "right" then
		x_pos = x_pos + (width - text_width)
	end

	-- For justified text, we need to calculate word spacing
	if alignment == "justify" then
		local spaces = text:gsub("[^ ]", ""):len() -- Count spaces
		local words = select(2, text:gsub("%S+", "")) + 1 -- Count words
		local available_width = self.page_width - self.margin_x[1] - self.margin_x[2]
		local extra_space = available_width - text_width
		local word_spacing = extra_space / spaces
		if word_spacing > 30 then
			word_spacing = 1
		end
		table.insert(
			content.streams,
			string.format(
				"BT\n/%s %s Tf\n%s %s %s rg\n%s Tw\n%s %s Td\n(%s) Tj\nET\n",
				fontName,
				numberToString(fontSize),
				numberToString(color[1]),
				numberToString(color[2]),
				numberToString(color[3]),
				numberToString(word_spacing), -- Set word spacing using Tw operator
				numberToString(x_pos),
				numberToString(self.currentYPos(self)),
				self:escapePdfText(text)
			)
		)
		return self
	end

	-- For left, center, and right alignment
	-- Check if text width exceeds available space for left/right alignment
	table.insert(
		content.streams,
		string.format(
			"BT\n/%s %s Tf\n%s %s %s rg\n0 Tw\n%s %s Td\n(%s) Tj\nET\n",
			fontName,
			numberToString(fontSize),
			numberToString(color[1]),
			numberToString(color[2]),
			numberToString(color[3]),
			numberToString(x_pos),
			numberToString(self.currentYPos(self)),
			self:escapePdfText(text)
		)
	)

	return self
end

-- Add paragraph to current page
function PDFGenerator:addParagraph(text, options)
	options = options or {}
	options.fontSize = options.fontSize or 12
	options.alignment = options.alignment or "left"
	options.width = options.width or (self.page_width - self.margin_x[1] - self.margin_x[2])
	options.color = options.color or "000000"
	options.newLine = options.newLine or true
	options.fontWeight = options.fontWeight or "normal"
	options.paddingX = options.paddingX or 0
	options.paddingY = options.paddingY or 0

	self.last_font = self.last_font or {}
	self.last_font.fontWeight = options.fontWeight

	local splittedText = string.split(text, "\n")

	for _, text in ipairs(splittedText) do
		local lines = self:splitTextToLines(text, options.fontSize, options.width - options.paddingX)
		for i, line in ipairs(lines) do
			if options.newLine == true then
				self.current_y = self.current_y + options.fontSize * 1.2 + options.paddingY
			end
			if
				self.out_of_page == false
				and self.page_height - self.current_y - self.header_height < self.margin_y[1] + self.margin_y[2]
			then
				self:addPage()
			end
			self:addText(line, options.fontSize, options.color, options.alignment, options.width)
		end
	end
	return self
end

-- Draw a table
function PDFGenerator:drawTable(options, table_options)
	options = options or {}
	self.current_table = table.merge(self.current_table, table_options or {})
	self.current_table.header_columns = options.header_columns
	self.current_table.data_columns = options.data_columns
	self.current_table.header_options = options.header_options
	self.current_table.data_options = options.data_options

	local first_line_height = self:calculateMaxHeight(options.header_columns)
	if options.data_columns[1] then
		first_line_height = first_line_height + self:calculateMaxHeight(options.data_columns[1])
	end
	if
		self.out_of_page == false
		and self.page_height - self.current_y - first_line_height - self.header_height
			< self.margin_y[1] + self.margin_y[2]
	then
		self:addPage()
	else
		if options.header_columns then
			self:drawTableRow(options.header_columns, options.header_options)
		end
	end

	for line, column in ipairs(options.data_columns) do
		if options.data_options.oddFillColor and line % 2 == 0 then
			options.data_options.fillColor = options.data_options.oddFillColor
		end

		if options.data_options.evenFillColor and line % 2 == 1 then
			options.data_options.fillColor = options.data_options.evenFillColor
		end

		self:calculateMaxHeight(column)
		if
			self.out_of_page == false
			and self.page_height - self.current_y - self.current_table.current_row.height - self.header_height
				< self.margin_y[1] + self.margin_y[2]
		then
			self:addPage()
		end

		self:drawTableRow(column, options.data_options)
	end

	self.current_table.header_columns = nil
	self.current_table.data_columns = nil
	self.current_table.header_options = nil
	self.current_table.data_options = nil
	self.current_table.current_row = { height = nil, padding_x = 5, padding_y = 5 }
end

-- Calculate maximum height needed for a collection of text items
function PDFGenerator:calculateMaxHeight(items)
	local max_height = 0

	for _, item in ipairs(items) do
		-- Ensure required fields exist
		local text = item.text or ""
		local fontSize = item.fontSize or 12
		local width = item.width or (self.page_width - self.margin_x[1] - self.margin_x[2])
		local padding_x = item.padding_x or self.current_table.padding_x or 5
		local padding_y = item.padding_y or self.current_table.padding_y or 5

		-- Split text into lines considering the available width
		local lines = string.split(text, "\n")
		local number_of_lines = 0

		for _, line in ipairs(lines) do
			local splitted_text = self:splitTextToLines(line, fontSize, width - (padding_x * 2))
			number_of_lines = number_of_lines + #splitted_text
		end

		-- Calculate height for this item
		local line_height = fontSize * 1.5 - (number_of_lines / 1.5) -- Standard line height
		local text_height = number_of_lines * line_height + (padding_y * 2) -- Include padding
		-- Update max_height if this item is taller
		if text_height > max_height then
			max_height = text_height
		end
		item.lines = number_of_lines
		item.height = number_of_lines * line_height
	end

	self.current_table.current_row.height = max_height

	return max_height
end

-- Draw a row table with multiple columns
function PDFGenerator:drawTableRow(columns, row_options)
	row_options = row_options or {}

	self:calculateMaxHeight(columns)

	local saved_x = self.current_x
	local saved_y = self.current_y
	-- Draw each column header
	for _, column in ipairs(columns) do
		-- Draw the cell using existing method
		local options = table.merge(row_options, column)
		-- options.text = nil
		-- options.height = column.height
		self:drawTableCell(column.text , options)
	end

	-- Reset cursor position
	self.current_x = saved_x
	self.current_y = saved_y + self.current_table.current_row.height

	return self
end

-- Draw a table cell with text and border
function PDFGenerator:drawTableCell(text, options)
	options = options or {}
	options.width = options.width or self.page_width - self.margin_x[1] - self.margin_x[2]
	options.fontSize = options.fontSize or 12
	options.fontWeight = options.fontWeight or "normal"
	options.textColor = options.textColor or "000"
	options.borderWidth = options.borderWidth or 1
	options.alignment = options.alignment or "left"
	options.fillColor = options.fillColor or "fff"
	options.borderColor = options.borderColor or "000"
	options.vertical_alignment = options.vertical_alignment or "top"

	-- Draw cell border using existing rectangle method
	self:drawRectangle({
		width = options.width,
		height = self.current_table.current_row.height,
		borderWidth = options.borderWidth,
		borderStyle = "solid",
		borderColor = options.borderColor,
		fillColor = options.fillColor,
		borderSides = options.borderSides,
	})

	-- Save current position before drawing text
	local saved_x = self.current_x
	local saved_y = self.current_y

	if options.alignment == "left" then
		self:moveX(self.current_table.padding_x)
	elseif options.alignment == "right" then
		self:moveX(-self.current_table.padding_x)
	end

	self:moveY(self.current_table.padding_y - 1)

	local paddingY = 0
	if options.vertical_alignment == "middle" then
		paddingY = (self.current_table.current_row.height - options.height - self.current_table.padding_y * 2) / 2
	end

	if options.vertical_alignment == "bottom" then
		paddingY = self.current_table.current_row.height - options.height - self.current_table.padding_y * 2
	end

	self:addParagraph(text, {
		fontSize = options.fontSize,
		fontWeight = options.fontWeight,
		alignment = options.alignment,
		width = options.width,
		color = options.textColor,
		paddingX = self.current_table.padding_x * 2,
		paddingY = paddingY,
	})

	-- Restore cursor position after drawing text
	self.current_x = saved_x
	self.current_y = saved_y
	-- Move cursor to end of cell
	self.current_x = self.current_x + options.width

	return self
end

-- Set current X position
function PDFGenerator:setX(x)
	self.current_x = x
	return self
end

-- Set current Y position
function PDFGenerator:setY(y)
	self.current_y = y
	return self
end

-- Move current X position
function PDFGenerator:moveX(x)
	self.current_x = self.current_x + x
end

-- Move current Y position
function PDFGenerator:moveY(y)
	self.current_y = self.current_y + y
end

-- Calcutate the current Y position based on margins and header
function PDFGenerator:currentYPos()
	return self.page_height - self.margin_y[1] - self.current_y - self.header_height
end

-- Draw line on current page
function PDFGenerator:drawLine(x1, y1, x2, y2, width, options)
	options = options or {}
	options.color = options.color or "000000"
	options.style = options.style or "solid" -- "solid", "dashed", "dotted"
	options.cap = options.cap or "butt" -- "butt", "round", "square"

	width = width or 1
	local rgb = PDFGenerator:hexToRGB(options.color)
	local content = self.contents[self.current_page_obj]

	-- Save graphics state
	table.insert(content.streams, "q\n")

	-- Set line width and color
	table.insert(content.streams, string.format("%s w\n", numberToString(width)))
	table.insert(
		content.streams,
		string.format("%s %s %s RG\n", numberToString(rgb[1]), numberToString(rgb[2]), numberToString(rgb[3]))
	)

	-- Set line style (dash pattern)
	if options.style == "dashed" then
		table.insert(content.streams, "[6 3] 0 d\n")
	elseif options.style == "dotted" then
		table.insert(content.streams, string.format("[%s %s] 0 d\n", numberToString(width), numberToString(width * 2)))
	else
		table.insert(content.streams, "[] 0 d\n")
	end

	-- Set line cap
	if options.cap == "round" then
		table.insert(content.streams, "1 J\n")
	elseif options.cap == "square" then
		table.insert(content.streams, "2 J\n")
	else
		table.insert(content.streams, "0 J\n")
	end

	-- Draw the line
	table.insert(
		content.streams,
		string.format(
			"%s %s m\n%s %s l\nS\nQ\n",
			numberToString(x1),
			numberToString(y1),
			numberToString(x2),
			numberToString(y2)
		)
	)

	return self
end

-- Draw circle on current page
-- borderColor and fillColor should be hex color codes (e.g., "000000" for black)
function PDFGenerator:drawCircle(radius, borderWidth, borderStyle, borderColor, fillColor)
	local x = self.margin_x[1] + self.current_x + radius
	local y = self.page_height - self.margin_y[1] - self.current_y - radius
	borderWidth = borderWidth or 1
	borderStyle = borderStyle or "solid"
	borderColor = borderColor or "000000" -- default black
	borderColor = PDFGenerator:hexToRGB(borderColor)
	fillColor = fillColor or "ffffff" -- default white
	fillColor = PDFGenerator:hexToRGB(fillColor)

	local content = self.contents[self.current_page_obj]

	-- Save graphics state
	table.insert(content.streams, "q\n")

	-- Set border color
	table.insert(
		content.streams,
		string.format(
			"%s %s %s RG\n",
			numberToString(borderColor[1]),
			numberToString(borderColor[2]),
			numberToString(borderColor[3])
		)
	)

	-- Set fill color
	table.insert(
		content.streams,
		string.format(
			"%s %s %s rg\n",
			numberToString(fillColor[1]),
			numberToString(fillColor[2]),
			numberToString(fillColor[3])
		)
	)

	-- Set line width
	table.insert(content.streams, string.format("%s w\n", numberToString(borderWidth)))

	-- Set dash pattern if needed
	if borderStyle == "dashed" then
		table.insert(content.streams, "[3 3] 0 d\n")
	end

	-- Draw circle using Bézier curves
	-- Move to start point
	table.insert(content.streams, string.format("%s %s m\n", numberToString(x + radius), numberToString(y)))

	-- Add four Bézier curves to approximate a circle
	local k = 0.552284749831 -- Magic number to make Bézier curves approximate a circle
	local kr = k * radius

	table.insert(
		content.streams,
		string.format(
			"%s %s %s %s %s %s c\n",
			numberToString(x + radius),
			numberToString(y + kr),
			numberToString(x + kr),
			numberToString(y + radius),
			numberToString(x),
			numberToString(y + radius)
		)
	)

	table.insert(
		content.streams,
		string.format(
			"%s %s %s %s %s %s c\n",
			numberToString(x - kr),
			numberToString(y + radius),
			numberToString(x - radius),
			numberToString(y + kr),
			numberToString(x - radius),
			numberToString(y)
		)
	)

	table.insert(
		content.streams,
		string.format(
			"%s %s %s %s %s %s c\n",
			numberToString(x - radius),
			numberToString(y - kr),
			numberToString(x - kr),
			numberToString(y - radius),
			numberToString(x),
			numberToString(y - radius)
		)
	)

	table.insert(
		content.streams,
		string.format(
			"%s %s %s %s %s %s c\n",
			numberToString(x + kr),
			numberToString(y - radius),
			numberToString(x + radius),
			numberToString(y - kr),
			numberToString(x + radius),
			numberToString(y)
		)
	)

	-- Fill and stroke the path and Restore graphics state
	table.insert(content.streams, "B\nQ\n")

	return self
end

-- Convert hex color to RGB values (0-1)
function PDFGenerator:hexToRGB(hex)
	self.rgb_colors = self.rgb_colors or {}
	if self.rgb_colors[hex] then
		return self.rgb_colors[hex]
	end

	-- Remove '#' if present
	hex = hex:gsub("#", "")
	-- If hex is 3 characters (shorthand), expand it to 6 characters
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	-- Convert hex to decimal and normalize to 0-1 range
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255

	self.rgb_colors[hex] = { r, g, b }
	return self.rgb_colors[hex]
end

-- Draw rectangle on current page
function PDFGenerator:drawRectangle(options)
	options = options or {}

	if
		self.out_of_page == false
		and self.page_height - self.current_y - options.height - self.header_height
			< self.margin_y[1] + self.margin_y[2]
	then
		self:addPage()
	end

	options.borderWidth = options.borderWidth or 1
	options.borderStyle = options.borderStyle or "solid"
	options.borderColor = options.borderColor or "000000" -- default gray
	options.borderColor = PDFGenerator:hexToRGB(options.borderColor)
	options.fillColor = options.fillColor or "ffffff" -- default gray
	options.fillColor = PDFGenerator:hexToRGB(options.fillColor)

	options.borderSides = options.borderSides or {}
	options.borderSides.left = options.borderSides.left or true
	options.borderSides.right = options.borderSides.right or true
	options.borderSides.top = options.borderSides.top or true
	options.borderSides.bottom = options.borderSides.bottom or true

	local content = self.contents[self.current_page_obj]

	-- Save graphics state
	table.insert(content.streams, "q\n")

	-- Set border color
	table.insert(
		content.streams,
		string.format(
			"%s %s %s RG\n",
			numberToString(options.borderColor[1]),
			numberToString(options.borderColor[2]),
			numberToString(options.borderColor[3])
		)
	)

	-- Set line width
	table.insert(content.streams, string.format("%s w\n", numberToString(options.borderWidth)))

	-- Set dash pattern if needed
	if options.borderStyle == "dashed" then
		table.insert(content.streams, "[3 3] 0 d\n")
	end

	-- If fill color is provided, set it and draw filled rectangle
	table.insert(
		content.streams,
		string.format(
			"%s %s %s rg\n",
			numberToString(options.fillColor[1]),
			numberToString(options.fillColor[2]),
			numberToString(options.fillColor[3])
		)
	)
	-- Draw filled and stroked rectangle
	table.insert(
		content.streams,
		string.format(
			"%s %s %s %s re\nf\n",
			numberToString(self.margin_x[1] + self.current_x),
			numberToString(self.currentYPos(self) - options.height),
			numberToString(options.width),
			numberToString(options.height)
		)
	)

	-- Draw left border
	if options.borderSides.left == true then
		table.insert(
			content.streams,
			string.format(
				"%s w\n%s %s m\n%s %s l\nS\n",
				numberToString(options.borderWidth),
				numberToString(self.margin_x[1] + self.current_x),
				numberToString(self.currentYPos(self) - options.height),
				numberToString(self.margin_x[1] + self.current_x),
				numberToString(self.currentYPos(self))
			)
		)
	end

	if options.borderSides.right == true then
		table.insert(
			content.streams,
			string.format(
				"%s w\n%s %s m\n%s %s l\nS\n",
				numberToString(options.borderWidth),
				numberToString(self.margin_x[1] + self.current_x + options.width),
				numberToString(self.currentYPos(self) - options.height),
				numberToString(self.margin_x[1] + self.current_x + options.width),
				numberToString(self.currentYPos(self))
			)
		)
	end

	if options.borderSides.top == true then
		table.insert(
			content.streams,
			string.format(
				"%s w\n%s %s m\n%s %s l\nS\n",
				numberToString(options.borderWidth),
				numberToString(self.margin_x[1] + self.current_x),
				numberToString(self.currentYPos(self)),
				numberToString(self.margin_x[1] + self.current_x + options.width),
				numberToString(self.currentYPos(self))
			)
		)
	end

	if options.borderSides.bottom == true then
		table.insert(
			content.streams,
			string.format(
				"%s w\n%s %s m\n%s %s l\nS\n",
				numberToString(options.borderWidth),
				numberToString(self.margin_x[1] + self.current_x),
				numberToString(self.currentYPos(self) - options.height),
				numberToString(self.margin_x[1] + self.current_x + options.width),
				numberToString(self.currentYPos(self) - options.height)
			)
		)
	end

	-- Restore graphics state
	table.insert(content.streams, "Q\n")

	return self
end

-- Draw a star on current page
function PDFGenerator:drawStar(outerRadius, branches, borderWidth, borderStyle, borderColor, fillColor)
	borderWidth = borderWidth or 1
	branches = branches or 5
	innerRadius = outerRadius * 0.382 -- Golden ratio for default inner radius
	borderStyle = borderStyle or "solid"
	borderColor = borderColor or "000000" -- default black
	borderColor = PDFGenerator:hexToRGB(borderColor)
	fillColor = fillColor or "ffffff" -- default white
	fillColor = PDFGenerator:hexToRGB(fillColor)

	local content = self.contents[self.current_page_obj]

	-- Save graphics state
	table.insert(content.streams, "q\n")

	-- Set border color
	table.insert(
		content.streams,
		string.format(
			"%s %s %s RG\n",
			numberToString(borderColor[1]),
			numberToString(borderColor[2]),
			numberToString(borderColor[3])
		)
	)

	-- Set fill color
	table.insert(
		content.streams,
		string.format(
			"%s %s %s rg\n",
			numberToString(fillColor[1]),
			numberToString(fillColor[2]),
			numberToString(fillColor[3])
		)
	)

	-- Set line width
	table.insert(content.streams, string.format("%s w\n", numberToString(borderWidth)))

	-- Set dash pattern if needed
	if borderStyle == "dashed" then
		table.insert(content.streams, "[3 3] 0 d\n")
	end

	-- Calculate star points
	local points = {}
	local angle = math.pi / branches

	for i = 0, (2 * branches - 1) do
		local radius = (i % 2 == 0) and outerRadius or innerRadius
		local currentAngle = i * angle - math.pi / 2
		local px = self.margin_x[1] + self.current_x + radius * math.cos(currentAngle) + outerRadius
		local py = self.page_height - self.margin_y[1] - self.current_y - radius * math.sin(currentAngle)
		table.insert(points, { px, py })
	end

	-- Draw the star
	table.insert(
		content.streams,
		string.format("%s %s m\n", numberToString(points[1][1]), numberToString(points[1][2]))
	)

	for i = 2, #points do
		table.insert(
			content.streams,
			string.format("%s %s l\n", numberToString(points[i][1]), numberToString(points[i][2]))
		)
	end

	-- Close the path and fill/stroke
	table.insert(content.streams, "h\nB\nQ\n")

	return self
end

local function get_jpeg_dimensions(data)
	local byte = string.byte
	local len = #data

	-- Must start with SOI marker (0xFFD8)
	if len < 4 or byte(data, 1) ~= 0xFF or byte(data, 2) ~= 0xD8 then
		return nil, nil, "Not a valid JPEG file"
	end

	local pos = 3
	while pos < len do
		if byte(data, pos) ~= 0xFF then
			return nil, nil, "Invalid JPEG marker"
		end

		local marker = byte(data, pos + 1)
		pos = pos + 2

		-- SOF markers (baseline/progressive/etc.)
		if marker >= 0xC0 and marker <= 0xCF and marker ~= 0xC4 and marker ~= 0xC8 and marker ~= 0xCC then
			-- Ensure enough bytes remain
			if pos + 7 > len then
				return nil, nil, "Truncated SOF segment"
			end
			-- skip: segment length(2) + precision(1)
			local h1, h2, w1, w2 = byte(data, pos + 3, pos + 6)
			local height = h1 * 256 + h2
			local width = w1 * 256 + w2
			return width, height
		else
			if pos + 1 > len then
				return nil, nil, "Unexpected end of file"
			end
			local s1, s2 = byte(data, pos, pos + 1)
			local segment_length = s1 * 256 + s2
			pos = pos + segment_length
		end
	end

	return nil, nil, "No SOF marker found"
end

-- Add image to PDF (imgData should be binary data)
function PDFGenerator:addImage(imgData, format)
	format = format:lower()
	if format ~= "jpeg" then
		error("Unsupported image format: " .. format)
	end

	-- Create image object
	local imageObj = getNewObjNum()
	local imgName = string.format("Im%d", #self.resources.images + 1)

	local width, height, err = get_jpeg_dimensions(imgData)

	-- Store image information
	self.resources.images[imgName] = {
		obj = imageObj,
		width = width,
		height = height,
	}

	-- Create image XObject
	local colorSpace = format == "jpeg" and "/DeviceRGB" or "/DeviceRGB"
	local filter = format == "jpeg" and "/DCTDecode" or "/FlateDecode"

	self.objects[imageObj] = string.format(
		"%d 0 obj\n<< /Type /XObject /Subtype /Image /Width %d /Height %d /ColorSpace %s /BitsPerComponent 8 /Filter %s /Length %d >>\nstream\n",
		imageObj,
		width,
		height,
		colorSpace,
		filter,
		#imgData
	) .. imgData .. "\nendstream\nendobj\n"

	return imgName
end

-- Draw image on current page
function PDFGenerator:drawImage(imgName, width)
	width = width or self.page_width - self.margin_x[1] - self.margin_x[2]

	if not self.resources.images[imgName] then
		error("Image not found: " .. imgName)
	end

	local image = self.resources.images[imgName]

	-- Check if image XObject is already included in page resources
	local pageObj = self.objects[self.current_page_obj]
	if not pageObj:find("/" .. imgName .. " %d+ 0 R") then
		-- Only update page resources if image not already included
		local imgRef = string.format("%d 0 R", image.obj)
		pageObj = pageObj:gsub("(/XObject << )(>>)", "%1/" .. imgName .. " " .. imgRef .. " %2")
		self.objects[self.current_page_obj] = pageObj
	end

	-- Draw image with corrected coordinate system
	local content = self.contents[self.current_page_obj]
	local height = image.height * width / image.width
	table.insert(
		content.streams,
		string.format(
			"q\n%s 0 0 %s %s %s cm\n/%s Do\nQ\n",
			numberToString(width),
			numberToString(height),
			numberToString(self.current_x + self.margin_x[1]),
			numberToString(self.currentYPos(self) - height),
			imgName
		)
	)

	self:moveY(height)
	return self
end

-- Set header
function PDFGenerator:setHeader(header)
	self.header = header
	return self
end

-- Set footer
function PDFGenerator:setFooter(footer)
	self.footer = footer
	return self
end

-- Draw header on current page
function PDFGenerator:drawHeader(pageId)
	-- Reset position to top of page
	self.current_x = 0
	self.current_y = 0 - self.header_height

	-- Execute header function
	self.header(pageId)
end

-- Draw footer on current page
function PDFGenerator:drawFooter(pageId)
	-- Reset position to top of page
	self.current_x = 0
	self.current_y = self.page_height - self.margin_y[2] - self.margin_y[1] - self.header_height
	-- Execute footer function
	self.footer(pageId)
end

function PDFGenerator:totalPage()
	return #self.page_list
end

-- Fit an SVG path into a width x height block at current position
-- signature: pdf:drawSvgPath(width, height, pathData, options)
function PDFGenerator:drawSvgPath(width, height, pathData, options)
	options = options or {}
	options.strokeColor = options.strokeColor or "000000"
	options.fillColor = options.fillColor or nil
	options.borderWidth = options.borderWidth or 1
	options.align = options.align or "min" -- "min" or "center"
	if options.scaleStroke == nil then
		options.scaleStroke = true
	end

	local x = self.current_x + self.margin_x[1]
	local y = self.page_height - self.current_y - self.margin_y[1] - height
	local nts = numberToString or function(n)
		return ("%.4f"):format(n)
	end
	local hexToRGB = self.hexToRGB and function(h)
		return self:hexToRGB(h)
	end or function(h)
		return { 0, 0, 0 }
	end
	local strokeRGB = hexToRGB(options.strokeColor)
	local fillRGB = options.fillColor and hexToRGB(options.fillColor) or nil
	local content = self.contents[self.current_page_obj]

	-- helper to parse numbers
	local function parseNumbers(str)
		local nums = {}
		for n in str:gmatch("([+-]?%d*%.?%d+)") do
			table.insert(nums, tonumber(n))
		end
		return nums
	end

	-- Compute bounding box from path
	local function computeBounds(path)
		local cx, cy = 0, 0
		local sx, sy = 0, 0
		local cpx, cpy = 0, 0
		local qx, qy = nil, nil
		local lastCmd
		local minx, miny = math.huge, math.huge
		local maxx, maxy = -math.huge, -math.huge
		local function updateBounds(...)
			local args = { ... }
			for i = 1, #args, 2 do
				local px, py = args[i], args[i + 1]
				if px and py then
					minx = math.min(minx, px)
					miny = math.min(miny, py)
					maxx = math.max(maxx, px)
					maxy = math.max(maxy, py)
				end
			end
		end

		for cmd, argsStr in path:gmatch("([MLHVCSQTZmlhvcsqtz])([^MLHVCSQTZmlhvcsqtz]*)") do
			local nums = parseNumbers(argsStr)
			local i = 1
			local function lastWasCubic()
				return lastCmd and (lastCmd:lower() == "c" or lastCmd:lower() == "s")
			end
			local function lastWasQuad()
				return lastCmd and (lastCmd:lower() == "q" or lastCmd:lower() == "t")
			end

			if cmd == "M" then
				while i <= #nums do
					cx, cy = nums[i], nums[i + 1]
					i = i + 2
					sx, sy = cx, cy
					updateBounds(cx, cy)
					lastCmd = "M"
				end
			elseif cmd == "m" then
				while i <= #nums do
					cx, cy = cx + nums[i], cy + nums[i + 1]
					i = i + 2
					sx, sy = cx, cy
					updateBounds(cx, cy)
					lastCmd = "m"
				end
			elseif cmd == "L" then
				while i <= #nums do
					cx, cy = nums[i], nums[i + 1]
					i = i + 2
					updateBounds(cx, cy)
					lastCmd = "L"
				end
			elseif cmd == "l" then
				while i <= #nums do
					cx, cy = cx + nums[i], cy + nums[i + 1]
					i = i + 2
					updateBounds(cx, cy)
					lastCmd = "l"
				end
			elseif cmd == "H" then
				while i <= #nums do
					cx = nums[i]
					i = i + 1
					updateBounds(cx, cy)
					lastCmd = "H"
				end
			elseif cmd == "h" then
				while i <= #nums do
					cx = cx + nums[i]
					i = i + 1
					updateBounds(cx, cy)
					lastCmd = "h"
				end
			elseif cmd == "V" then
				while i <= #nums do
					cy = nums[i]
					i = i + 1
					updateBounds(cx, cy)
					lastCmd = "V"
				end
			elseif cmd == "v" then
				while i <= #nums do
					cy = cy + nums[i]
					i = i + 1
					updateBounds(cx, cy)
					lastCmd = "v"
				end
			elseif cmd == "C" then
				while i <= #nums do
					local x1, y1, x2, y2, x, y =
						nums[i], nums[i + 1], nums[i + 2], nums[i + 3], nums[i + 4], nums[i + 5]
					i = i + 6
					updateBounds(x1, y1, x2, y2, x, y)
					cpx, cpy = x2, y2
					cx, cy = x, y
					lastCmd = "C"
				end
			elseif cmd == "c" then
				while i <= #nums do
					local x1, y1 = cx + nums[i], cy + nums[i + 1]
					local x2, y2 = cx + nums[i + 2], cy + nums[i + 3]
					local x, y = cx + nums[i + 4], cy + nums[i + 5]
					i = i + 6
					updateBounds(x1, y1, x2, y2, x, y)
					cpx, cpy = x2, y2
					cx, cy = x, y
					lastCmd = "c"
				end
			elseif cmd == "S" then
				while i <= #nums do
					local x2, y2, x, y = nums[i], nums[i + 1], nums[i + 2], nums[i + 3]
					i = i + 4
					local x1, y1 = lastWasCubic() and (2 * cx - cpx), (2 * cy - cpy) or cx, cy
					updateBounds(x1, y1, x2, y2, x, y)
					cpx, cpy = x2, y2
					cx, cy = x, y
					lastCmd = "S"
				end
			elseif cmd == "s" then
				while i <= #nums do
					local x2, y2, x, y = cx + nums[i], cy + nums[i + 1], cx + nums[i + 2], cy + nums[i + 3]
					i = i + 4
					local x1, y1 = lastWasCubic() and (2 * cx - cpx), (2 * cy - cpy) or cx, cy
					updateBounds(x1, y1, x2, y2, x, y)
					cpx, cpy = x2, y2
					cx, cy = x, y
					lastCmd = "s"
				end
			elseif cmd == "Q" then
				while i <= #nums do
					local x1, y1, x, y = nums[i], nums[i + 1], nums[i + 2], nums[i + 3]
					i = i + 4
					updateBounds(x1, y1, x, y)
					qx, qy = x1, y1
					cx, cy = x, y
					lastCmd = "Q"
				end
			elseif cmd == "q" then
				while i <= #nums do
					local x1, y1, x, y = cx + nums[i], cy + nums[i + 1], cx + nums[i + 2], cy + nums[i + 3]
					i = i + 4
					updateBounds(x1, y1, x, y)
					qx, qy = x1, y1
					cx, cy = x, y
					lastCmd = "q"
				end
			elseif cmd == "T" then
				while i <= #nums do
					local x, y = nums[i], nums[i + 1]
					i = i + 2
					local x1, y1 = lastWasQuad() and qx and (2 * cx - qx), (2 * cy - qy) or cx, cy
					updateBounds(x1, y1, x, y)
					qx, qy = x1, y1
					cx, cy = x, y
					lastCmd = "T"
				end
			elseif cmd == "t" then
				while i <= #nums do
					local x, y = cx + nums[i], cy + nums[i + 1]
					i = i + 2
					local x1, y1 = lastWasQuad() and qx and (2 * cx - qx), (2 * cy - qy) or cx, cy
					updateBounds(x1, y1, x, y)
					qx, qy = x1, y1
					cx, cy = x, y
					lastCmd = "t"
				end
			elseif cmd == "Z" or cmd == "z" then
				updateBounds(sx, sy)
				cx, cy = sx, sy
				lastCmd = cmd
			end
		end
		if minx == math.huge then
			minx, miny, maxx, maxy = 0, 0, 0, 0
		end
		return minx, miny, maxx, maxy
	end

	-- Based on SVG spec (https://www.w3.org/TR/SVG/implnote.html)
	local function arcToBeziers(x1, y1, rx, ry, angle, largeArc, sweep, x2, y2)
		local rad = math.rad(angle or 0)
		local cosA, sinA = math.cos(rad), math.sin(rad)

		-- Step 1: Compute transformed coords
		local dx2, dy2 = (x1 - x2) / 2, (y1 - y2) / 2
		local x1p = cosA * dx2 + sinA * dy2
		local y1p = -sinA * dx2 + cosA * dy2

		rx = math.abs(rx)
		ry = math.abs(ry)

		-- Correct radii
		local rCheck = (x1p ^ 2) / (rx ^ 2) + (y1p ^ 2) / (ry ^ 2)
		if rCheck > 1 then
			local scale = math.sqrt(rCheck)
			rx, ry = rx * scale, ry * scale
		end

		-- Step 2: Compute center
		local sign = (largeArc == sweep) and -1 or 1
		local num = rx ^ 2 * ry ^ 2 - rx ^ 2 * y1p ^ 2 - ry ^ 2 * x1p ^ 2
		local den = rx ^ 2 * y1p ^ 2 + ry ^ 2 * x1p ^ 2
		local coef = sign * math.sqrt(math.max(0, num / den))
		local cxp = coef * (rx * y1p) / ry
		local cyp = coef * (-ry * x1p) / rx

		-- Center in absolute coords
		local cx = cosA * cxp - sinA * cyp + (x1 + x2) / 2
		local cy = sinA * cxp + cosA * cyp + (y1 + y2) / 2

		-- Step 3: Angles
		local function angleBetween(ux, uy, vx, vy)
			local dot = ux * vx + uy * vy
			local len = math.sqrt((ux ^ 2 + uy ^ 2) * (vx ^ 2 + vy ^ 2))
			local ang = math.acos(math.min(math.max(dot / len, -1), 1))
			if ux * vy - uy * vx < 0 then
				ang = -ang
			end
			return ang
		end

		local theta1 = angleBetween(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
		local deltaTheta = angleBetween((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)

		if not sweep and deltaTheta > 0 then
			deltaTheta = deltaTheta - 2 * math.pi
		end
		if sweep and deltaTheta < 0 then
			deltaTheta = deltaTheta + 2 * math.pi
		end

		-- Step 4: Split arc into ≤90° pieces
		local segments = math.ceil(math.abs(deltaTheta / (math.pi / 2)))
		local result = {}
		local delta = deltaTheta / segments
		for i = 0, segments - 1 do
			local t1 = theta1 + i * delta
			local t2 = t1 + delta
			local cosT1, sinT1 = math.cos(t1), math.sin(t1)
			local cosT2, sinT2 = math.cos(t2), math.sin(t2)

			-- endpoints
			local p1x = cx + rx * cosA * cosT1 - ry * sinA * sinT1
			local p1y = cy + rx * sinA * cosT1 + ry * cosA * sinT1
			local p2x = cx + rx * cosA * cosT2 - ry * sinA * sinT2
			local p2y = cy + rx * sinA * cosT2 + ry * cosA * sinT2

			-- control points
			local alpha = math.tan((t2 - t1) / 4) * 4 / 3
			local q1x = p1x - alpha * (rx * cosA * sinT1 + ry * sinA * cosT1)
			local q1y = p1y - alpha * (rx * sinA * sinT1 - ry * cosA * cosT1)
			local q2x = p2x + alpha * (rx * cosA * sinT2 + ry * sinA * cosT2)
			local q2y = p2y + alpha * (rx * sinA * sinT2 - ry * cosA * cosT2)

			table.insert(result, { q1x, q1y, q2x, q2y, p2x, p2y })
		end
		return result
	end

	local minx, miny, maxx, maxy = computeBounds(pathData)
	local origW, origH = maxx - minx, maxy - miny
	if origW == 0 then
		origW = 1
	end
	if origH == 0 then
		origH = 1
	end
	local scale = math.min(width / origW, height / origH)
	local offsetX, offsetY = x - minx * scale, y - miny * scale
	if options.align == "center" then
		offsetX = offsetX + (width - origW * scale) / 2
		offsetY = offsetY + (height - origH * scale) / 2
	end

	local function transform(px, py)
		return px * scale + offsetX, py * scale + offsetY
	end

	-- === emit path ===
	local strokeW = options.borderWidth
	if options.scaleStroke then
		strokeW = strokeW * scale
	end
	if strokeW <= 0 then
		strokeW = options.borderWidth
	end
	table.insert(content.streams, "q\n")
	table.insert(content.streams, string.format("%s w\n", nts(strokeW)))
	if strokeRGB then
		table.insert(
			content.streams,
			string.format("%s %s %s RG\n", nts(strokeRGB[1]), nts(strokeRGB[2]), nts(strokeRGB[3]))
		)
	end
	if fillRGB then
		table.insert(content.streams, string.format("%s %s %s rg\n", nts(fillRGB[1]), nts(fillRGB[2]), nts(fillRGB[3])))
	end

	-- parse & render
	local cx, cy = 0, 0
	local sx, sy = 0, 0
	local cpx, cpy = 0, 0
	local qx, qy = nil, nil
	local lastCmd = nil
	for cmd, argsStr in pathData:gmatch("([AMLHVCSQTZamlhvcsqtz])([^AMLHVCSQTZamlhvcsqtz]*)") do
		local nums = parseNumbers(argsStr)
		local i = 1
		local function lastWasCubic()
			return lastCmd and (lastCmd:lower() == "c" or lastCmd:lower() == "s")
		end
		local function lastWasQuad()
			return lastCmd and (lastCmd:lower() == "q" or lastCmd:lower() == "t")
		end

		if cmd == "M" then
			-- first pair is move, subsequent pairs are L
			if #nums >= 2 then
				cx, cy = nums[1], nums[2]
				i = 3
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s m\n", nts(tx), nts(ty)))
				sx, sy = cx, cy
				lastCmd = "M"
			end
			while i <= #nums do
				cx, cy = nums[i], nums[i + 1]
				i = i + 2
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "L"
			end
		elseif cmd == "m" then
			if #nums >= 2 then
				cx, cy = cx + nums[1], cy + nums[2]
				i = 3
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s m\n", nts(tx), nts(ty)))
				sx, sy = cx, cy
				lastCmd = "m"
			end
			while i <= #nums do
				cx, cy = cx + nums[i], cy + nums[i + 1]
				i = i + 2
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "l"
			end
		elseif cmd == "L" then
			while i <= #nums do
				cx, cy = nums[i], nums[i + 1]
				i = i + 2
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "L"
			end
		elseif cmd == "l" then
			while i <= #nums do
				cx, cy = cx + nums[i], cy + nums[i + 1]
				i = i + 2
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "l"
			end
		elseif cmd == "H" then
			while i <= #nums do
				cx = nums[i]
				i = i + 1
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "H"
			end
		elseif cmd == "h" then
			while i <= #nums do
				cx = cx + nums[i]
				i = i + 1
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "h"
			end
		elseif cmd == "V" then
			while i <= #nums do
				cy = nums[i]
				i = i + 1
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "V"
			end
		elseif cmd == "v" then
			while i <= #nums do
				cy = cy + nums[i]
				i = i + 1
				local tx, ty = transform(cx, cy)
				table.insert(content.streams, string.format("%s %s l\n", nts(tx), nts(ty)))
				lastCmd = "v"
			end
		elseif cmd == "C" then
			while i <= #nums do
				local x1, y1, x2, y2, x, y = nums[i], nums[i + 1], nums[i + 2], nums[i + 3], nums[i + 4], nums[i + 5]
				i = i + 6
				local tx1, ty1 = transform(x1, y1)
				local tx2, ty2 = transform(x2, y2)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				cpx, cpy = x2, y2
				cx, cy = x, y
				lastCmd = "C"
			end
		elseif cmd == "c" then
			while i <= #nums do
				local x1, y1 = cx + nums[i], cy + nums[i + 1]
				local x2, y2 = cx + nums[i + 2], cy + nums[i + 3]
				local x, y = cx + nums[i + 4], cy + nums[i + 5]
				i = i + 6
				local tx1, ty1 = transform(x1, y1)
				local tx2, ty2 = transform(x2, y2)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				cpx, cpy = x2, y2
				cx, cy = x, y
				lastCmd = "c"
			end
		elseif cmd == "S" then
			while i <= #nums do
				local x2, y2, x, y = nums[i], nums[i + 1], nums[i + 2], nums[i + 3]
				i = i + 4
				local x1, y1
				if lastWasCubic() then
					x1, y1 = 2 * cx - cpx, 2 * cy - cpy
				else
					x1, y1 = cx, cy
				end
				local tx1, ty1 = transform(x1, y1)
				local tx2, ty2 = transform(x2, y2)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				cpx, cpy = x2, y2
				cx, cy = x, y
				lastCmd = "S"
			end
		elseif cmd == "s" then
			while i <= #nums do
				local x2, y2, x, y = cx + nums[i], cy + nums[i + 1], cx + nums[i + 2], cy + nums[i + 3]
				i = i + 4
				local x1, y1
				if lastWasCubic() then
					x1, y1 = 2 * cx - cpx, 2 * cy - cpy
				else
					x1, y1 = cx, cy
				end
				local tx1, ty1 = transform(x1, y1)
				local tx2, ty2 = transform(x2, y2)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				cpx, cpy = x2, y2
				cx, cy = x, y
				lastCmd = "s"
			end
		elseif cmd == "Q" then
			while i <= #nums do
				local x1, y1, x, y = nums[i], nums[i + 1], nums[i + 2], nums[i + 3]
				i = i + 4
				-- convert quadratic to cubic:
				local c1x = cx + (2 / 3) * (x1 - cx)
				local c1y = cy + (2 / 3) * (y1 - cy)
				local c2x = x + (2 / 3) * (x1 - x)
				local c2y = y + (2 / 3) * (y1 - y)
				local tx1, ty1 = transform(c1x, c1y)
				local tx2, ty2 = transform(c2x, c2y)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				qx, qy = x1, y1
				cx, cy = x, y
				lastCmd = "Q"
			end
		elseif cmd == "q" then
			while i <= #nums do
				local x1, y1, x, y = cx + nums[i], cy + nums[i + 1], cx + nums[i + 2], cy + nums[i + 3]
				i = i + 4
				local c1x = cx + (2 / 3) * (x1 - cx)
				local c1y = cy + (2 / 3) * (y1 - cy)
				local c2x = x + (2 / 3) * (x1 - x)
				local c2y = y + (2 / 3) * (y1 - y)
				local tx1, ty1 = transform(c1x, c1y)
				local tx2, ty2 = transform(c2x, c2y)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				qx, qy = x1, y1
				cx, cy = x, y
				lastCmd = "q"
			end
		elseif cmd == "T" then
			while i <= #nums do
				local x, y = nums[i], nums[i + 1]
				i = i + 2
				local x1, y1
				if lastWasQuad() and qx then
					x1, y1 = 2 * cx - qx, 2 * cy - qy
				else
					x1, y1 = cx, cy
				end
				local c1x = cx + (2 / 3) * (x1 - cx)
				local c1y = cy + (2 / 3) * (y1 - cy)
				local c2x = x + (2 / 3) * (x1 - x)
				local c2y = y + (2 / 3) * (y1 - y)
				local tx1, ty1 = transform(c1x, c1y)
				local tx2, ty2 = transform(c2x, c2y)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				qx, qy = x1, y1
				cx, cy = x, y
				lastCmd = "T"
			end
		elseif cmd == "t" then
			while i <= #nums do
				local x, y = cx + nums[i], cy + nums[i + 1]
				i = i + 2
				local x1, y1
				if lastWasQuad() and qx then
					x1, y1 = 2 * cx - qx, 2 * cy - qy
				else
					x1, y1 = cx, cy
				end
				local c1x = cx + (2 / 3) * (x1 - cx)
				local c1y = cy + (2 / 3) * (y1 - cy)
				local c2x = x + (2 / 3) * (x1 - x)
				local c2y = y + (2 / 3) * (y1 - y)
				local tx1, ty1 = transform(c1x, c1y)
				local tx2, ty2 = transform(c2x, c2y)
				local tx, ty = transform(x, y)
				table.insert(
					content.streams,
					string.format("%s %s %s %s %s %s c\n", nts(tx1), nts(ty1), nts(tx2), nts(ty2), nts(tx), nts(ty))
				)
				qx, qy = x1, y1
				cx, cy = x, y
				lastCmd = "t"
			end
		elseif cmd == "A" or cmd == "a" then
			while i + 6 <= #nums do
				local rx, ry = nums[i], nums[i + 1]
				local xAxisRot = nums[i + 2]
				local largeArcFlag = nums[i + 3]
				local sweepFlag = nums[i + 4]
				local x, y

				if cmd == "a" then
					x, y = cx + nums[i + 5], cy + nums[i + 6]
				else
					x, y = nums[i + 5], nums[i + 6]
				end

				local beziers = arcToBeziers(cx, cy, rx, ry, xAxisRot, largeArcFlag ~= 0, sweepFlag ~= 0, x, y)

				for _, b in ipairs(beziers) do
					local x1, y1, x2, y2, x3, y3 = table.unpack(b)
					table.insert(
						content.streams,
						string.format("%s %s %s %s %s %s c\n", nts(x1), nts(y1), nts(x2), nts(y2), nts(x3), nts(y3))
					)
				end

				cx, cy = x, y
				i = i + 7
			end
		elseif cmd == "Z" or cmd == "z" then
			-- emit closepath; PDF 'h' closes current subpath
			table.insert(content.streams, "h\n")
			cx, cy = sx, sy
			lastCmd = cmd
		end
	end

	if fillRGB then
		table.insert(content.streams, "B\nQ\n")
	else
		table.insert(content.streams, "S\nQ\n")
	end
	return self
end

-- ChartBar
function PDFGenerator:BarChart(barData, labels)
	local chartWidth = 555 - 100
	local chartHeight = 60
	local barWidth = chartWidth / #barData - 5
	local maxValue = 100
	local startX = 25
	-- Draw chart background
	self:drawRectangle({
		width = chartWidth + 40,
		height = chartHeight + 40 + 10,
		borderWidth = 1,
		borderColor = "cccccc",
		fillColor = "f8f9fa",
	})

	local startY = self.current_y + 20

	-- Draw bars
	for i, value in ipairs(barData) do
		local barHeight = (value / maxValue) * chartHeight
		local x = startX + (i - 1) * (barWidth + 5) - 2
		local y = startY + chartHeight - barHeight

		-- Bar color based on value
		local color = value > 80 and "4CAF50" or (value > 60 and "FF9800" or "F44336")

		self:setX(x)
		self:setY(startY + chartHeight - barHeight)
		self:drawRectangle({
			width = barWidth,
			height = barHeight,
			borderWidth = 0.3,
			borderColor = "333333",
			fillColor = color,
		})

		-- Value label on top of bar
		self:setX(x)
		self:setY(startY + chartHeight - barHeight - 5)
		self:addText(tostring(value) .. " ", 8, "000000", "center", barWidth)

		-- Month label below bar
		self:setX(x)
		self:setY(startY + chartHeight + 10)
		self:addText(labels[i] .. " 2025", 6, "000000", "center", barWidth)
		self:moveY(20)
	end

	self:setX(0)
	self:moveY(5)
end
-- /ChartBar

-- Generate PDF and return as string
function PDFGenerator:generate()
	local output = {}
	-- Add header and footer to all pages
	self.out_of_page = true
	for current_page, pageId in pairs(self.page_list) do
		-- Set current page for header/footer drawing
		self.current_page_obj = pageId

		self:drawHeader(current_page)
		self:drawFooter(current_page)
	end
	self.out_of_page = false
	-- Add header
	table.insert(output, "%PDF-1.7\n%âãÏÓ\n")

	-- Add pages tree
	local pageTree = { string.format("%d 0 obj\n<< /Type /Pages /Kids [", self.pages_obj) }
	for _, page in ipairs(self.page_list) do
		table.insert(pageTree, string.format("%d 0 R ", page))
	end
	table.insert(pageTree, string.format("] /Count %d >>\nendobj\n", #self.page_list))
	self.objects[self.pages_obj] = table.concat(pageTree)

	-- Add catalog
	self.objects[self.root] =
		string.format("%d 0 obj\n<< /Type /Catalog /Pages %d 0 R >>\nendobj\n", self.root, self.pages_obj)

	-- Write content streams
	for pageId, content in pairs(self.contents) do
		local stream = table.concat(content.streams)

		self.objects[content.id] =
			string.format("%d 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n", content.id, #stream, stream)
	end

	-- Write objects and collect xref information
	local xref = {}
	local offset = #output[1] -- Start after header

	local objNums = {}
	for objNum in pairs(self.objects) do
		table.insert(objNums, objNum)
	end
	table.sort(objNums) -- Ensure consistent order

	for _, objNum in ipairs(objNums) do
		xref[objNum] = offset
		local objData = self.objects[objNum]
		table.insert(output, objData)
		offset = offset + #objData
	end

	-- Write xref table
	local xrefOffset = offset
	table.insert(output, "xref\n")
	table.insert(output, string.format("0 %d\n", objCounter))
	table.insert(output, "0000000000 65535 f \n")

	for i = 1, objCounter - 1 do
		if xref[i] then
			table.insert(output, string.format("%010d 00000 n \n", xref[i]))
		else
			table.insert(output, "0000000000 00000 f \n")
		end
	end

	-- Write trailer
	table.insert(
		output,
		string.format("trailer\n<< /Size %d /Root %d 0 R /Info %d 0 R >>\n", objCounter, self.root, self.info)
	)
	table.insert(output, string.format("startxref\n%d\n%%%%EOF", xrefOffset))

	-- Concatenate all parts and return
	return table.concat(output)
end

return PDFGenerator
