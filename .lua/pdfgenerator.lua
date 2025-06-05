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

function PDFGenerator:getHashValues(hash)
		local values = {}
		for _, value in pairs(hash) do
				table.insert(values, math.floor(value + 0.5))
		end
		return values
end

-- Convert number to PDF string format
local function numberToString(num)
		return string.format("%.2f", num)
end

local fontHelveticaMetrics = {
		bold = decodeJson([[{"32":277.83203125,"33":333.0078125,"34":474.12109375,"35":556.15234375,"36":556.15234375,"37":889.16015625,"38":722.16796875,"39":237.79296875,"40":333.0078125,"41":333.0078125,"42":389.16015625,"43":583.984375,"44":277.83203125,"45":333.0078125,"46":277.83203125,"47":277.83203125,"48":556.15234375,"49":556.15234375,"50":556.15234375,"51":556.15234375,"52":556.15234375,"53":556.15234375,"54":556.15234375,"55":556.15234375,"56":556.15234375,"57":556.15234375,"58":333.0078125,"59":333.0078125,"60":583.984375,"61":583.984375,"62":583.984375,"63":610.83984375,"64":975.09765625,"65":722.16796875,"66":722.16796875,"67":722.16796875,"68":722.16796875,"69":666.9921875,"70":610.83984375,"71":777.83203125,"72":722.16796875,"73":277.83203125,"74":556.15234375,"75":722.16796875,"76":610.83984375,"77":833.0078125,"78":722.16796875,"79":777.83203125,"80":666.9921875,"81":777.83203125,"82":722.16796875,"83":666.9921875,"84":610.83984375,"85":722.16796875,"86":666.9921875,"87":943.84765625,"88":666.9921875,"89":666.9921875,"90":610.83984375,"91":333.0078125,"92":277.83203125,"93":333.0078125,"94":583.984375,"95":556.15234375,"96":333.0078125,"97":556.15234375,"98":610.83984375,"99":556.15234375,"100":610.83984375,"101":556.15234375,"102":333.0078125,"103":610.83984375,"104":610.83984375,"105":277.83203125,"106":277.83203125,"107":556.15234375,"108":277.83203125,"109":889.16015625,"110":610.83984375,"111":610.83984375,"112":610.83984375,"113":610.83984375,"114":389.16015625,"115":556.15234375,"116":333.0078125,"117":610.83984375,"118":556.15234375,"119":777.83203125,"120":556.15234375,"121":556.15234375,"122":500,"123":389.16015625,"124":279.78515625,"125":389.16015625,"126":583.984375,"127":722.16796875,"128":722.16796875,"129":722.16796875,"130":722.16796875,"131":722.16796875,"132":722.16796875,"133":722.16796875,"134":722.16796875,"135":722.16796875,"136":722.16796875,"137":722.16796875,"138":722.16796875,"139":722.16796875,"140":722.16796875,"141":722.16796875,"142":722.16796875,"143":722.16796875,"144":722.16796875,"145":722.16796875,"146":722.16796875,"147":722.16796875,"148":722.16796875,"149":722.16796875,"150":722.16796875,"151":722.16796875,"152":722.16796875,"153":722.16796875,"154":722.16796875,"155":722.16796875,"156":722.16796875,"157":722.16796875,"158":722.16796875,"159":722.16796875,"160":277.83203125,"161":333.0078125,"162":556.15234375,"163":556.15234375,"164":556.15234375,"165":556.15234375,"166":279.78515625,"167":556.15234375,"168":333.0078125,"169":736.81640625,"170":370.1171875,"171":556.15234375,"172":583.984375,"173":333.0078125,"174":736.81640625,"175":333.0078125,"176":399.90234375,"177":548.828125,"178":333.0078125,"179":333.0078125,"180":333.0078125,"181":576.171875,"182":556.15234375,"183":277.83203125,"184":333.0078125,"185":333.0078125,"186":365.234375,"187":556.15234375,"188":833.984375,"189":833.984375,"190":833.984375,"191":610.83984375,"192":722.16796875,"193":722.16796875,"194":722.16796875,"195":722.16796875,"196":722.16796875,"197":722.16796875,"198":1000,"199":722.16796875,"200":666.9921875,"201":666.9921875,"202":666.9921875,"203":666.9921875,"204":277.83203125,"205":277.83203125,"206":277.83203125,"207":277.83203125,"208":722.16796875,"209":722.16796875,"210":777.83203125,"211":777.83203125,"212":777.83203125,"213":777.83203125,"214":777.83203125,"215":583.984375,"216":777.83203125,"217":722.16796875,"218":722.16796875,"219":722.16796875,"220":722.16796875,"221":666.9921875,"222":666.9921875,"223":610.83984375,"224":556.15234375,"225":556.15234375,"226":556.15234375,"227":556.15234375,"228":556.15234375,"229":556.15234375,"230":889.16015625,"231":556.15234375,"232":556.15234375,"233":556.15234375,"234":556.15234375,"235":556.15234375,"236":277.83203125,"237":277.83203125,"238":277.83203125,"239":277.83203125,"240":610.83984375,"241":610.83984375,"242":610.83984375,"243":610.83984375,"244":610.83984375,"245":610.83984375,"246":610.83984375,"247":548.828125,"248":610.83984375,"249":610.83984375,"250":610.83984375,"251":610.83984375,"252":610.83984375,"253":556.15234375,"254":610.83984375,"255":556.15234375,"256":722.16796875}]]),
		normal = decodeJson([[{"32":277.83203125,"33":277.83203125,"34":354.98046875,"35":556.15234375,"36":556.15234375,"37":889.16015625,"38":666.9921875,"39":190.91796875,"40":333.0078125,"41":333.0078125,"42":389.16015625,"43":583.984375,"44":277.83203125,"45":333.0078125,"46":277.83203125,"47":277.83203125,"48":556.15234375,"49":556.15234375,"50":556.15234375,"51":556.15234375,"52":556.15234375,"53":556.15234375,"54":556.15234375,"55":556.15234375,"56":556.15234375,"57":556.15234375,"58":277.83203125,"59":277.83203125,"60":583.984375,"61":583.984375,"62":583.984375,"63":556.15234375,"64":1015.13671875,"65":666.9921875,"66":666.9921875,"67":722.16796875,"68":722.16796875,"69":666.9921875,"70":610.83984375,"71":777.83203125,"72":722.16796875,"73":277.83203125,"74":500,"75":666.9921875,"76":556.15234375,"77":833.0078125,"78":722.16796875,"79":777.83203125,"80":666.9921875,"81":777.83203125,"82":722.16796875,"83":666.9921875,"84":610.83984375,"85":722.16796875,"86":666.9921875,"87":943.84765625,"88":666.9921875,"89":666.9921875,"90":610.83984375,"91":277.83203125,"92":277.83203125,"93":277.83203125,"94":469.23828125,"95":556.15234375,"96":333.0078125,"97":556.15234375,"98":556.15234375,"99":500,"100":556.15234375,"101":556.15234375,"102":277.83203125,"103":556.15234375,"104":556.15234375,"105":222.16796875,"106":222.16796875,"107":500,"108":222.16796875,"109":833.0078125,"110":556.15234375,"111":556.15234375,"112":556.15234375,"113":556.15234375,"114":333.0078125,"115":500,"116":277.83203125,"117":556.15234375,"118":500,"119":722.16796875,"120":500,"121":500,"122":500,"123":333.984375,"124":259.765625,"125":333.984375,"126":583.984375,"127":633.7890625,"128":633.7890625,"129":633.7890625,"130":633.7890625,"131":633.7890625,"132":633.7890625,"133":633.7890625,"134":633.7890625,"135":633.7890625,"136":633.7890625,"137":633.7890625,"138":633.7890625,"139":633.7890625,"140":633.7890625,"141":633.7890625,"142":633.7890625,"143":633.7890625,"144":633.7890625,"145":633.7890625,"146":633.7890625,"147":633.7890625,"148":633.7890625,"149":633.7890625,"150":633.7890625,"151":633.7890625,"152":633.7890625,"153":633.7890625,"154":633.7890625,"155":633.7890625,"156":633.7890625,"157":633.7890625,"158":633.7890625,"159":633.7890625,"160":277.83203125,"161":333.0078125,"162":556.15234375,"163":556.15234375,"164":556.15234375,"165":556.15234375,"166":259.765625,"167":556.15234375,"168":333.0078125,"169":736.81640625,"170":370.1171875,"171":556.15234375,"172":583.984375,"173":333.0078125,"174":736.81640625,"175":333.0078125,"176":399.90234375,"177":548.828125,"178":333.0078125,"179":333.0078125,"180":333.0078125,"181":576.171875,"182":537.109375,"183":277.83203125,"184":333.0078125,"185":333.0078125,"186":365.234375,"187":556.15234375,"188":833.984375,"189":833.984375,"190":833.984375,"191":610.83984375,"192":666.9921875,"193":666.9921875,"194":666.9921875,"195":666.9921875,"196":666.9921875,"197":666.9921875,"198":1000,"199":722.16796875,"200":666.9921875,"201":666.9921875,"202":666.9921875,"203":666.9921875,"204":277.83203125,"205":277.83203125,"206":277.83203125,"207":277.83203125,"208":722.16796875,"209":722.16796875,"210":777.83203125,"211":777.83203125,"212":777.83203125,"213":777.83203125,"214":777.83203125,"215":583.984375,"216":777.83203125,"217":722.16796875,"218":722.16796875,"219":722.16796875,"220":722.16796875,"221":666.9921875,"222":666.9921875,"223":610.83984375,"224":556.15234375,"225":556.15234375,"226":556.15234375,"227":556.15234375,"228":556.15234375,"229":556.15234375,"230":889.16015625,"231":500,"232":556.15234375,"233":556.15234375,"234":556.15234375,"235":556.15234375,"236":277.83203125,"237":277.83203125,"238":277.83203125,"239":277.83203125,"240":556.15234375,"241":556.15234375,"242":556.15234375,"243":556.15234375,"244":556.15234375,"245":556.15234375,"246":556.15234375,"247":548.828125,"248":610.83984375,"249":556.15234375,"250":556.15234375,"251":556.15234375,"252":556.15234375,"253":500,"254":556.15234375,"255":500,"256":666.9921875}]])
}

-- Create new PDF document
function PDFGenerator.new(options)
		objCounter = 1
		local self = {
				objects = {},
				current_page = 0,
				current_page_obj = nil,
				page_list = {},	-- Array to store page objects
				pages_obj = nil, -- Object number for pages tree
				images = {},
				contents = {},
				catalog = nil,
				info = nil,
				root = nil,
				page_width = 595,
				page_height = 842,
				header_height = 0,
				margin_x = {50, 50},
				margin_y = {50, 80},
				current_x = 0,
				current_y = 0,
				resources = {},
				font_metrics = {},
				fonts = {},
				last_font = { fontFamily = "Helvetica", fontWeight = "normal" },
				current_table = {
						current_row = {
								height = nil
						},
						padding_x = 5,
						padding_y = 5,
						header_columns = nil,
						data_columns = nil,
						header_options = nil,
						data_options = nil
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
		self.resources = {
				fonts = {},
				images = {}
		}

		-- Add required PDF objects
		self.objects[self.info] = string.format(
				"%d 0 obj\n<< /Producer (Lua PDF Generator 1.0) /CreationDate (D:%s) >>\nendobj\n",
				self.info,
				os.date("!%Y%m%d%H%M%S")
		)

		return setmetatable(self, {__index = PDFGenerator})
end

-- Start a new page
function PDFGenerator:addPage(width, height)
		width = width or 595		-- Default A4 width in points
		height = height or 842	-- Default A4 height in points

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
		self.contents[pageObj] = {
				id = contentObj,
				stream = "",
		}

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

		for _, font in ipairs(self.fonts) do
				self:useFont(font[1], font[2])
		end

		self:setY(0)
		self:setX(0)

		-- Display table header
		if self.current_table.header_columns then
				self:drawRowTable(self.current_table.header_columns, self.current_table.header_options)
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
end

-- Add custom font (TrueType)
function PDFGenerator:addCustomFont(fontPath, fontName, fontWeight)
		local fontObj = getNewObjNum()
		local fontFileObj = getNewObjNum()
		local fontDescObj = getNewObjNum()

		table.insert(self.fonts, {fontName, fontWeight})

		fullFontName = fontName .. "-" .. fontWeight

		-- Read font file
		local fontData = loadAsset(fontPath)
		local fontMetrics = loadAsset(fontPath:gsub("%.ttf$", ".json"))

		self.custom_fonts = self.custom_fonts or {}
		self.custom_fonts[fullFontName] = fontObj

		if fontMetrics then
				self.font_metrics[fullFontName] = decodeJson(fontMetrics)
		end

		-- Font descriptor object
		self.objects[fontDescObj] = string.format(
				"%d 0 obj\n<< /Type /Font /%s /Flags 32 /FontBBox [-250 -250 1250 1250] /ItalicAngle 0 /Ascent 750 /Descent -250 /CapHeight 750 /StemV 80 /StemH 80 /FontFile2 %d 0 R >>\nendobj\n",
				fontDescObj,
				fullFontName,
				fontFileObj
		)

		-- Font file stream object
		self.objects[fontFileObj] = string.format(
				"%d 0 obj\n<< /Length %d /Length1 %d >>\nstream\n%sendstream\nendobj\n",
				fontFileObj,
				#fontData,
				#fontData,
				fontData
		)

		-- Font object
		self.objects[fontObj] = string.format(
				"%d 0 obj\n<< /Type /Font /Subtype /TrueType /BaseFont /%s /FirstChar 32 /LastChar 255 /Encoding /WinAnsiEncoding /FontDescriptor %d 0 R	>>\nendobj\n",
				fontObj,
				fullFontName,
				fontDescObj
		)

		self:useFont(fontName, fontWeight)
end

-- Use custom font for text
function PDFGenerator:useFont(fontName, fontWeight)
		fontWeight = fontWeight or "normal"
		self.last_font = self.last_font or {}
		self.last_font.fontFamily = fontName
		self.last_font.fontWeight = fontWeight

		-- Store the current font name to be used in addText
		self.current_font = fontName

		-- Update the page's resources to include the custom font
		local pageObj = self.current_page_obj

		-- Check if there's already a Font dictionary
		if self.objects[pageObj]:find("(/Font << [^>]+ >>)") then
				-- Append new font to existing dictionary
				self.objects[pageObj] = self.objects[pageObj]:gsub(
						"(/Font << [^>]+ >>)",
						function(fontDict)
								return string.format("%s /%s %d 0 R",
										fontDict:sub(1, -3), -- Remove trailing ">>"
										fontName .. "-" .. self.last_font.fontWeight,
										self.custom_fonts[fontName .. "-" .. self.last_font.fontWeight]
								) .. " >>"
						end
				)
		else
				-- Create new Font dictionary
				self.objects[pageObj] = self.objects[pageObj]:gsub(
						"(/Resources << )",
						string.format("/Resources << /Font << /F1 %d 0 R /%s %d 0 R >> ",
								self.basic_font_obj,
								fontName .. "-" .. self.last_font.fontWeight,
								self.custom_fonts[fontName .. "-" .. self.last_font.fontWeight]
						)
				)
		end

		return self
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

		local fontMetrics = fontHelveticaMetrics -- default font metrics

		self.font_metrics = self.font_metrics or {}
		if self.font_metrics[self.last_font.fontFamily .. "-" .. fontWeight] then
				fontMetrics = self.font_metrics[self.last_font.fontFamily .. "-" .. fontWeight]
		else
				fontMetrics = fontMetrics[fontWeight] or fontMetrics["normal"]
		end

		local width = 0
		for i = 1, #text do
				local charCode = string.byte(text, i)
				width = width + (fontMetrics[""..charCode] or 556) -- default to 556 for unknown chars
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
		color = color or "000"	-- default black
		alignment = alignment or "justify"	-- default left alignment
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
		if alignment == "justify"	then
				local spaces = text:gsub("[^ ]", ""):len()	-- Count spaces
				local words = select(2, text:gsub("%S+", "")) + 1	-- Count words
				local available_width = self.page_width - self.margin_x[1] - self.margin_x[2]
				local extra_space = available_width - text_width
				local word_spacing = extra_space / spaces
				if word_spacing > 30 then
						word_spacing = 1
				end
				content.stream = content.stream .. string.format(
						"BT\n/%s %s Tf\n%s %s %s rg\n%s Tw\n%s %s Td\n(%s) Tj\nET\n",
						fontName,
						numberToString(fontSize),
						numberToString(color[1]),
						numberToString(color[2]),
						numberToString(color[3]),
						numberToString(word_spacing),	-- Set word spacing using Tw operator
						numberToString(x_pos),
						numberToString(self.currentYPos(self)),
						EscapeHtml(text)
				)
				return self
		end

		-- For left, center, and right alignment
		-- Check if text width exceeds available space for left/right alignment
		content.stream = content.stream .. string.format(
	      "BT\n/%s %s Tf\n%s %s %s rg\n0 Tw\n%s %s Td\n(%s) Tj\nET\n",
        fontName,
        numberToString(fontSize),
        numberToString(color[1]),
        numberToString(color[2]),
        numberToString(color[3]),
        numberToString(x_pos),
        numberToString(self.currentYPos(self)),
        EscapeHtml(text)
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

    self.last_font = self.last_font or {}
    self.last_font.fontWeight = options.fontWeight

    local lines = self:splitTextToLines(text, options.fontSize, options.width - options.paddingX)
    for i, line in ipairs(lines) do
        if options.newLine == true then
            self.current_y = self.current_y + options.fontSize*1.2
        end
        if self.out_of_page == false and self.page_height - self.current_y - self.header_height < self.margin_y[1] + self.margin_y[2] then
            self:addPage()
        end
        self:addText(line, options.fontSize, options.color, options.alignment, options.width)
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

    self:drawRowTable(options.header_columns, options.header_options)
    for line, column in ipairs(options.data_columns) do
        if options.data_options.oddFillColor and line % 2 == 0 then
            options.data_options.fillColor = options.data_options.oddFillColor
        end

        if options.data_options.evenFillColor and line % 2 == 1 then
            options.data_options.fillColor = options.data_options.evenFillColor
        end

        self:drawRowTable(column, options.data_options)
    end

    self.current_table.header_columns = nil
    self.current_table.data_columns = nil
    self.current_table.header_options = nil
    self.current_table.data_options = nil
    self.current_table.current_row = { height = nil, padding_x = 5, padding_y = 5}
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
        local lines = self:splitTextToLines(text, fontSize, width - (padding_x * 2))

        -- Calculate height for this item
        local line_height = fontSize * 1.5  -- Standard line height
        local text_height = #lines * line_height + 2 + (padding_y * 2)  -- Include padding
        -- Update max_height if this item is taller
        if text_height > max_height then
            max_height = text_height
        end
    end

    self.current_table.current_row.height = max_height

    return max_height
end

-- Draw a row table with multiple columns
function PDFGenerator:drawRowTable(columns, row_options)
    row_options = row_options or {}

    self:calculateMaxHeight(columns)

    if self.out_of_page == false and self.page_height - self.current_y - self.current_table.current_row.height - self.header_height  < self.margin_y[1] + self.margin_y[2] then
        self:addPage()
    end

    self:calculateMaxHeight(columns)

    local saved_x = self.current_x
    local saved_y = self.current_y
    -- Draw each column header
    for _, column in ipairs(columns) do
        -- Draw the cell using existing method
        local options = table.merge(row_options, column)
        options.text = nil
        self:drawTableCell(column.text, options)
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
    options.textColor = options.textColor or "000"
    options.borderWidth = options.borderWidth or 1
    options.alignment = options.alignment or "left"
    options.fillColor = options.fillColor or "fff"
    options.borderColor = options.borderColor or "000"

    -- Draw cell border using existing rectangle method
    self:drawRectangle({
        width = options.width,
        height = self.current_table.current_row.height,
        borderWidth = options.borderWidth,
        borderStyle = "solid",
        borderColor = options.borderColor,
        fillColor = options.fillColor,
        borderSides = options.borderSides;
    })

    -- Save current position before drawing text
    local saved_x = self.current_x
    local saved_y = self.current_y

    if options.alignment == "left" then
        self:moveX(self.current_table.padding_x)
    elseif options.alignment == "right" then
        self:moveX(-self.current_table.padding_x)
    end

    self:moveY(self.current_table.padding_y)

    self:addParagraph(text, {
        fontSize = options.fontSize,
        alignment = options.alignment,
        width = options.width,
        color = options.textColor,
        paddingX = self.current_table.padding_x * 2
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
function PDFGenerator:drawLine(x1, y1, x2, y2, width)
    width = width or 1
    local content = self.contents[self.current_page_obj]
    content.stream = content.stream .. string.format(
        "%s w\n%s %s m\n%s %s l\nS\n",
        numberToString(width),
        numberToString(x1),
        numberToString(y1),
        numberToString(x2),
        numberToString(y2)
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
    borderColor = borderColor or "000000"  -- default black
    borderColor = PDFGenerator:hexToRGB(borderColor)
    fillColor = fillColor or "ffffff"  -- default white
    fillColor = PDFGenerator:hexToRGB(fillColor)

    local content = self.contents[self.current_page_obj]

    -- Save graphics state
    content.stream = content.stream .. "q\n"

    -- Set border color
    content.stream = content.stream .. string.format(
        "%s %s %s RG\n",
        numberToString(borderColor[1]),
        numberToString(borderColor[2]),
        numberToString(borderColor[3])
    )

    -- Set fill color
    content.stream = content.stream .. string.format(
        "%s %s %s rg\n",
        numberToString(fillColor[1]),
        numberToString(fillColor[2]),
        numberToString(fillColor[3])
    )

    -- Set line width
    content.stream = content.stream .. string.format("%s w\n", numberToString(borderWidth))

    -- Set dash pattern if needed
    if borderStyle == "dashed" then
        content.stream = content.stream .. "[3 3] 0 d\n"
    end

    -- Draw circle using Bézier curves
    -- Move to start point
    content.stream = content.stream .. string.format(
        "%s %s m\n",
        numberToString(x + radius),
        numberToString(y)
    )

    -- Add four Bézier curves to approximate a circle
    local k = 0.552284749831  -- Magic number to make Bézier curves approximate a circle
    local kr = k * radius

    content.stream = content.stream .. string.format(
        "%s %s %s %s %s %s c\n",
        numberToString(x + radius), numberToString(y + kr),
        numberToString(x + kr), numberToString(y + radius),
        numberToString(x), numberToString(y + radius)
    )

    content.stream = content.stream .. string.format(
        "%s %s %s %s %s %s c\n",
        numberToString(x - kr), numberToString(y + radius),
        numberToString(x - radius), numberToString(y + kr),
        numberToString(x - radius), numberToString(y)
    )

    content.stream = content.stream .. string.format(
        "%s %s %s %s %s %s c\n",
        numberToString(x - radius), numberToString(y - kr),
        numberToString(x - kr), numberToString(y - radius),
        numberToString(x), numberToString(y - radius)
    )

    content.stream = content.stream .. string.format(
        "%s %s %s %s %s %s c\n",
        numberToString(x + kr), numberToString(y - radius),
        numberToString(x + radius), numberToString(y - kr),
        numberToString(x + radius), numberToString(y)
    )

    -- Fill and stroke the path
    content.stream = content.stream .. "B\n"

    -- Restore graphics state
    content.stream = content.stream .. "Q\n"

    return self
end

-- Convert hex color to RGB values (0-1)
function PDFGenerator:hexToRGB(hex)
    -- Remove '#' if present
    hex = hex:gsub("#", "")
    -- If hex is 3 characters (shorthand), expand it to 6 characters
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    -- Convert hex to decimal and normalize to 0-1 range
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255

    return {r, g, b}
end

-- Draw rectangle on current page
function PDFGenerator:drawRectangle(options)
    options = options or {}
    options.borderWidth = options.borderWidth or 1
    options.borderStyle = options.borderStyle or "solid"
    options.borderColor = options.borderColor or "000000"  -- default gray
    options.borderColor = PDFGenerator:hexToRGB(options.borderColor)
    options.fillColor = options.fillColor or "ffffff"  -- default gray
    options.fillColor = PDFGenerator:hexToRGB(options.fillColor)

    options.borderSides = options.borderSides or {}
    options.borderSides.left = options.borderSides.left or true
    options.borderSides.right = options.borderSides.right or true
    options.borderSides.top = options.borderSides.top or true
    options.borderSides.bottom = options.borderSides.bottom or true

    local content = self.contents[self.current_page_obj]

    -- Save graphics state
    content.stream = content.stream .. "q\n"

    -- Set border color
    content.stream = content.stream .. string.format(
        "%s %s %s RG\n",
        numberToString(options.borderColor[1]),
        numberToString(options.borderColor[2]),
        numberToString(options.borderColor[3])
    )

    -- Set line width
    content.stream = content.stream .. string.format("%s w\n", numberToString(options.borderWidth))

    -- Set dash pattern if needed
    if options.borderStyle == "dashed" then
        content.stream = content.stream .. "[3 3] 0 d\n"
    end

    -- If fill color is provided, set it and draw filled rectangle
    content.stream = content.stream .. string.format(
        "%s %s %s rg\n",
        numberToString(options.fillColor[1]),
        numberToString(options.fillColor[2]),
        numberToString(options.fillColor[3])
    )
    -- Draw filled and stroked rectangle
    content.stream = content.stream .. string.format(
        "%s %s %s %s re\nf\n",
        numberToString(self.margin_x[1] + self.current_x),
        numberToString(self.currentYPos(self) - options.height),
        numberToString(options.width),
        numberToString(options.height)
    )

    -- Draw left border
    if options.borderSides.left == true then
        content.stream = content.stream .. string.format(
            "%s w\n%s %s m\n%s %s l\nS\n",
            numberToString(options.borderWidth),
            numberToString(self.margin_x[1] + self.current_x),
            numberToString(self.currentYPos(self) - options.height),
            numberToString(self.margin_x[1] + self.current_x),
            numberToString(self.currentYPos(self))
        )
    end

    if options.borderSides.right == true then
        content.stream = content.stream .. string.format(
            "%s w\n%s %s m\n%s %s l\nS\n",
            numberToString(options.borderWidth),
            numberToString(self.margin_x[1] + self.current_x + options.width),
            numberToString(self.currentYPos(self) - options.height),
            numberToString(self.margin_x[1] + self.current_x + options.width),
            numberToString(self.currentYPos(self))
        )
    end

    if options.borderSides.top == true then
        content.stream = content.stream .. string.format(
            "%s w\n%s %s m\n%s %s l\nS\n",
            numberToString(options.borderWidth),
            numberToString(self.margin_x[1] + self.current_x),
            numberToString(self.currentYPos(self)),
            numberToString(self.margin_x[1] + self.current_x + options.width),
            numberToString(self.currentYPos(self))
        )
    end

    if options.borderSides.bottom == true then
        content.stream = content.stream .. string.format(
            "%s w\n%s %s m\n%s %s l\nS\n",
            numberToString(options.borderWidth),
            numberToString(self.margin_x[1] + self.current_x),
            numberToString(self.currentYPos(self) - options.height),
            numberToString(self.margin_x[1] + self.current_x + options.width),
            numberToString(self.currentYPos(self) - options.height)
        )
    end

    -- Restore graphics state
    content.stream = content.stream .. "Q\n"

    return self
end

-- Draw a star on current page
function PDFGenerator:drawStar(outerRadius, branches, borderWidth, borderStyle, borderColor, fillColor)
    borderWidth = borderWidth or 1
    branches = branches or 5
    innerRadius = outerRadius * 0.382 -- Golden ratio for default inner radius
    borderStyle = borderStyle or "solid"
    borderColor = borderColor or "000000"  -- default black
    borderColor = PDFGenerator:hexToRGB(borderColor)
    fillColor = fillColor or "ffffff"  -- default white
    fillColor = PDFGenerator:hexToRGB(fillColor)

    local content = self.contents[self.current_page_obj]

    -- Save graphics state
    content.stream = content.stream .. "q\n"

    -- Set border color
    content.stream = content.stream .. string.format(
        "%s %s %s RG\n",
        numberToString(borderColor[1]),
        numberToString(borderColor[2]),
        numberToString(borderColor[3])
    )

    -- Set fill color
    content.stream = content.stream .. string.format(
        "%s %s %s rg\n",
        numberToString(fillColor[1]),
        numberToString(fillColor[2]),
        numberToString(fillColor[3])
    )

    -- Set line width
    content.stream = content.stream .. string.format("%s w\n", numberToString(borderWidth))

    -- Set dash pattern if needed
    if borderStyle == "dashed" then
        content.stream = content.stream .. "[3 3] 0 d\n"
    end

    -- Calculate star points
    local points = {}
    local angle = math.pi / branches

    for i = 0, (2 * branches - 1) do
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        local currentAngle = i * angle - math.pi / 2
        local px = self.margin_x[1] + self.current_x + radius * math.cos(currentAngle) + outerRadius
        local py = self.page_height - self.margin_y[1] - self.current_y - radius * math.sin(currentAngle)
        table.insert(points, {px, py})
    end

    -- Draw the star
    content.stream = content.stream .. string.format(
        "%s %s m\n",
        numberToString(points[1][1]),
        numberToString(points[1][2])
    )

    for i = 2, #points do
        content.stream = content.stream .. string.format(
            "%s %s l\n",
            numberToString(points[i][1]),
            numberToString(points[i][2])
        )
    end

    -- Close the path and fill/stroke
    content.stream = content.stream .. "h\nB\n"

    -- Restore graphics state
    content.stream = content.stream .. "Q\n"

    return self
end

-- Add image to PDF (imgData should be binary data)
function PDFGenerator:addImage(imgData, width, height, format)
    format = format:lower()
    if format ~= "jpeg" then
        error("Unsupported image format: " .. format)
    end

    -- Create image object
    local imageObj = getNewObjNum()
    local imgName = string.format("Im%d", #self.resources.images + 1)

    -- Store image information
    self.resources.images[imgName] = {
        obj = imageObj,
        width = width,
        height = height
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
    content.stream = content.stream .. string.format(
        "q\n%s 0 0 %s %s %s cm\n/%s Do\nQ\n",
        numberToString(width),
        numberToString(height),
        numberToString(self.current_x + self.margin_x[1]),
        numberToString(self.currentYPos(self) - height),
        imgName
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
    local pageTree = string.format(
        "%d 0 obj\n<< /Type /Pages /Kids [",
        self.pages_obj
    )
    for _, page in ipairs(self.page_list) do
        pageTree = pageTree .. string.format("%d 0 R ", page)
    end
    pageTree = pageTree .. string.format("] /Count %d >>\nendobj\n", #self.page_list)
    self.objects[self.pages_obj] = pageTree

    -- Add catalog
    self.objects[self.root] = string.format(
        "%d 0 obj\n<< /Type /Catalog /Pages %d 0 R >>\nendobj\n",
        self.root,
        self.pages_obj
    )

    -- Write content streams
    for pageId, content in pairs(self.contents) do
        self.objects[content.id] = string.format(
            "%d 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n",
            content.id,
            #content.stream,
            content.stream
        )
    end

    -- Write objects and collect xref information
    local xref = {}
    local offset = #output[1]  -- Start after header

    local objNums = {}
    for objNum in pairs(self.objects) do
        table.insert(objNums, objNum)
    end
    table.sort(objNums)  -- Ensure consistent order

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
    table.insert(output, string.format(
        "trailer\n<< /Size %d /Root %d 0 R /Info %d 0 R >>\n",
        objCounter,
        self.root,
        self.info
    ))
    table.insert(output, string.format("startxref\n%d\n%%%%EOF", xrefOffset))

    -- Concatenate all parts and return
    return table.concat(output)
end

return PDFGenerator
