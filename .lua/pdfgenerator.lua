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

-- Create new PDF document
function PDFGenerator.new(options)
    objCounter = 1
    local self = {
        objects = {},
        current_page = 0,
        current_page_obj = nil,
        page_list = {},  -- Array to store page objects
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
    self.resources = { fonts = {}, images = {} }

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
    width = width or 595    -- Default A4 width in points
    height = height or 842  -- Default A4 height in points

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
    self.contents[pageObj] = { id = contentObj, stream = "" }

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
    assert(fontMetrics, "You need the metrics json file")

    self.custom_fonts = self.custom_fonts or {}
    self.custom_fonts[fullFontName] = fontObj

    self.font_metrics[fullFontName] = decodeJson(fontMetrics)
    -- Validate and normalize font metrics for better compatibility
    self:validateFontMetrics(fullFontName)

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
        local width = fontMetrics[""..i] or 556
        table.insert(widths, math.floor(width + 0.5))
    end

    return table.concat(widths, " ")
end

-- Create ToUnicode stream for better text extraction and rendering
function PDFGenerator:createToUnicodeStream()
    local toUnicodeObj = getNewObjNum()
    local toUnicodeContent = "/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n/CMapName /Adobe-Identity-UCS def\n/CMapType 2 def\n1 begincodespacerange\n<0020> <00FF>\nendcodespacerange\n"

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
    if not text then return "" end

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
    local result = ""
    for i = 1, #escaped do
        local byte = string.byte(escaped, i)
        if byte >= 32 and byte <= 126 then
            result = result .. string.char(byte)
        else
            result = result .. string.format("\\%03o", byte)
        end
    end

    return result
end

-- Validate and normalize font metrics for better cross-browser compatibility
function PDFGenerator:validateFontMetrics(fontName)
    local metrics = self.font_metrics[fontName]
    if not metrics then return end

    -- Ensure all required characters have valid widths
    for i = 32, 255 do
        if not metrics[""..i] or metrics[""..i] <= 0 then
            metrics[""..i] = 556
        end
    end

    -- Normalize widths to ensure they're reasonable
    for i = 32, 255 do
        if metrics[""..i] then
            -- Ensure width is within reasonable bounds (100-2000 font units)
            if metrics[""..i] < 100 then
                metrics[""..i] = 100
            elseif metrics[""..i] > 2000 then
                metrics[""..i] = 2000
            end
        end
    end
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
        pageContent = pageContent:gsub(
            "(/Font << [^>]+ >>)",
            function(fontDict)
                return string.format("%s /%s %d 0 R",
                    fontDict:sub(1, -3), -- Remove trailing ">>"
                    fullFontName,
                    self.custom_fonts[fullFontName]
                ) .. " >>"
            end
        )
    else
        -- Create new font dictionary
        pageContent = pageContent:gsub(
            "(/Resources << )",
            string.format("/Resources << /Font << /F1 %d 0 R /F2 %d 0 R /%s %d 0 R >> ",
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
    color = color or "000"  -- default black
    alignment = alignment or "justify"  -- default left alignment
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
    if alignment == "justify"  then
            local spaces = text:gsub("[^ ]", ""):len()  -- Count spaces
            local words = select(2, text:gsub("%S+", "")) + 1  -- Count words
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
                    numberToString(word_spacing),  -- Set word spacing using Tw operator
                    numberToString(x_pos),
                    numberToString(self.currentYPos(self)),
                    self:escapePdfText(text)
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
        self:escapePdfText(text)
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

    local lines = self:splitTextToLines(text, options.fontSize, options.width - options.paddingX)
    for i, line in ipairs(lines) do
        if options.newLine == true then
            self.current_y = self.current_y + options.fontSize*1.2 + options.paddingY
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
        local text_height = #lines * line_height + (padding_y * 2)  -- Include padding
        -- Update max_height if this item is taller
        if text_height > max_height then
            max_height = text_height
        end
        item.lines = #lines
        item.height = #lines * line_height
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
        options.height = column.height
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
    options.vertical_alignment = options.vertical_alignment or "top"

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

    local paddingY = 0
    if options.vertical_alignment == "middle" then
        paddingY = (self.current_table.current_row.height - options.height - self.current_table.padding_y * 2) / 2
    end

    if options.vertical_alignment == "bottom" then
        paddingY = self.current_table.current_row.height - options.height - self.current_table.padding_y * 2
    end

    self:addParagraph(text, {
        fontSize = options.fontSize,
        alignment = options.alignment,
        width = options.width,
        color = options.textColor,
        paddingX = self.current_table.padding_x * 2,
        paddingY = paddingY
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

    if self.out_of_page == false and self.page_height - self.current_y - options.height - self.header_height < self.margin_y[1] + self.margin_y[2] then
        self:addPage()
    end

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

-- Basic SVG support
-- Add SVG to current page
function PDFGenerator:addSVG(svgData, width, height, options)
    options = options or {}
    width = width or 100
    height = height or 100
    options.x = options.x or self.current_x
    options.y = options.y or self.current_y

    -- Ensure we're on a valid page
    if not self.current_page_obj then
        self:addPage()
    end

    -- Parse SVG data
    local svgContent = self:parseSVG(svgData)
    local content = self.contents[self.current_page_obj]

    -- Check if SVG fits within page boundaries
    if self.out_of_page == false and self.page_height - self.current_y - height - self.header_height < self.margin_y[1] + self.margin_y[2] then
        self:addPage()
        content = self.contents[self.current_page_obj]
    end

    -- Save graphics state
    content.stream = content.stream .. "q\n"

    -- Apply scaling and translation
    local scaleX = width / (svgContent.width or 100)
    local scaleY = height / (svgContent.height or 100)
    content.stream = content.stream .. string.format(
        "%s 0 0 %s %s %s cm\n",
        numberToString(scaleX),
        numberToString(scaleY),
        numberToString(self.margin_x[1] + options.x),
        numberToString(self:currentYPos() - height)
    )

    -- Process SVG elements
    for _, element in ipairs(svgContent.elements) do
        if element.type == "path" then
            self:drawSVGPath(element, content)
        end
    end

    -- Restore graphics state
    content.stream = content.stream .. "Q\n"

    -- Update cursor position
    self:moveY(height)
    return self
end

-- Parse SVG string into a table of elements
function PDFGenerator:parseSVG(svgData)
    local svg = {
        width = 100,
        height = 100,
        elements = {}
    }

    -- Extract width and height from SVG tag
    local w, h = svgData:match('width="(%d+%.?%d*)"[^>]*height="(%d+%.?%d*)"')
    if w and h then
        svg.width = tonumber(w)
        svg.height = tonumber(h)
    end

    -- Parse path elements
    for pathData, fill, stroke, strokeWidth in svgData:gmatch('<path%s+d="([^"]+)"%s+fill="([^"]*)"%s+stroke="([^"]*)"%s+stroke%-width="([^"]*)"%s*/>') do
        table.insert(svg.elements, {
            type = "path",
            d = pathData,
            fill = fill ~= "none" and fill or nil,
            stroke = stroke ~= "none" and stroke or nil,
            strokeWidth = tonumber(strokeWidth) or 1
        })
    end

    -- Support <circle> elements in SVG
    -- Improved <circle> SVG parsing and ensure all attribute orders are supported
    for circleTag in svgData:gmatch("<circle%s+.-/>") do
        local cx = circleTag:match('cx="([^"]+)"')
        local cy = circleTag:match('cy="([^"]+)"')
        local r = circleTag:match('r="([^"]+)"')
        local fill = circleTag:match('fill="([^"]*)"')
        local stroke = circleTag:match('stroke="([^"]*)"')
        local strokeWidth = circleTag:match('stroke%-width="([^"]*)"')
        if cx and cy and r then
            -- Convert SVG circle to a path (PDF does not have a native circle primitive)
            -- Use 4 Bézier curves to approximate a circle
            local cx_num = tonumber(cx)
            local cy_num = tonumber(cy)
            local r_num = tonumber(r)
            local kappa = 0.552284749831  -- approximation constant for Bézier circle

            local x0 = cx_num - r_num
            local y0 = cy_num
            local x1 = cx_num
            local y1 = cy_num - r_num
            local x2 = cx_num + r_num
            local y2 = cy_num
            local x3 = cx_num
            local y3 = cy_num + r_num

            local ox = r_num * kappa
            local oy = r_num * kappa

            -- Compose path data for a circle using Bézier curves
            local d = string.format(
                "M %f %f " ..
                "C %f %f %f %f %f %f " ..
                "C %f %f %f %f %f %f " ..
                "C %f %f %f %f %f %f " ..
                "C %f %f %f %f %f %f Z",
                x2, y2,
                x2, y2 + oy, x3 + ox, y3, x3, y3,
                x3 - ox, y3, x0, y0 + oy, x0, y0,
                x0, y0 - oy, x1 - ox, y1, x1, y1,
                x1 + ox, y1, x2, y2 - oy, x2, y2
            )

            table.insert(svg.elements, {
                type = "path",
                d = d,
                fill = fill and fill ~= "none" and fill or nil,
                stroke = stroke and stroke ~= "none" and stroke or nil,
                strokeWidth = strokeWidth and tonumber(strokeWidth) or 1
            })
        end
    end

    -- Debug: Log parsed elements
    if #svg.elements == 0 then
        print("Warning: No SVG path elements parsed")
    end

    return svg
end

-- Draw SVG path in PDF content stream
function PDFGenerator:drawSVGPath(element, content)
    local fillColor = element.fill and self:hexToRGB(element.fill) or {1, 1, 1} -- Default white
    local strokeColor = element.stroke and self:hexToRGB(element.stroke) or {0, 0, 0} -- Default black
    local strokeWidth = element.strokeWidth or 1

    -- Set fill color
    if element.fill then
        content.stream = content.stream .. string.format(
            "%s %s %s rg\n",
            numberToString(fillColor[1]),
            numberToString(fillColor[2]),
            numberToString(fillColor[3])
        )
    end

    -- Set stroke color and width
    if element.stroke then
        content.stream = content.stream .. string.format(
            "%s %s %s RG\n",
            numberToString(strokeColor[1]),
            numberToString(strokeColor[2]),
            numberToString(strokeColor[3])
        )
        content.stream = content.stream .. string.format("%s w\n", numberToString(strokeWidth))
    end

    -- Parse and draw path commands
    local pathCommands = self:parseSVGPath(element.d)
    --assert(#pathCommands == 0,"Warning: No valid path commands parsed for path: " .. element.d)

    for _, cmd in ipairs(pathCommands) do
        if cmd.type == "M" then
            content.stream = content.stream .. string.format(
                "%s %s m\n",
                numberToString(cmd.x),
                numberToString(cmd.y)
            )
        elseif cmd.type == "L" then
            content.stream = content.stream .. string.format(
                "%s %s l\n",
                numberToString(cmd.x),
                numberToString(cmd.y)
            )
        elseif cmd.type == "C" then
            content.stream = content.stream .. string.format(
                "%s %s %s %s %s %s c\n",
                numberToString(cmd.x1),
                numberToString(cmd.y1),
                numberToString(cmd.x2),
                numberToString(cmd.y2),
                numberToString(cmd.x),
                numberToString(cmd.y)
            )
        elseif cmd.type == "Z" then
            content.stream = content.stream .. "h\n"
        end
    end

    -- Apply fill and/or stroke
    if element.fill and element.stroke then
        content.stream = content.stream .. "B\n"
    elseif element.fill then
        content.stream = content.stream .. "f\n"
    elseif element.stroke then
        content.stream = content.stream .. "S\n"
    end
end

-- Parse SVG path data into a list of commands
function PDFGenerator:parseSVGPath(pathData)
    local commands = {}
    local currentX, currentY = 0, 0
    local lastControlX, lastControlY = nil, nil
    local tokens = {}

    -- Normalize path data: replace commas with spaces, collapse multiple spaces
    pathData = pathData:gsub(",", " "):gsub("%s+", " ")
    -- Split into tokens, handling concatenated commands (e.g., M10 -> M, 10)
    local tempTokens = {}
    for token in pathData:gmatch("[^%s]+") do
        if token:match("^[MLCmlczZshvHV]") then
            local cmd = token:sub(1, 1)
            local rest = token:sub(2)
            table.insert(tokens, cmd)
            if rest ~= "" then
                table.insert(tokens, rest)
            end
        else
            table.insert(tokens, token)
        end
    end

    -- Debug: Log tokens
    print("Debug: Parsed tokens: " .. table.concat(tokens, ", "))

    local i = 1
    while i <= #tokens do
        local cmd = tokens[i]
        if cmd == "M" or cmd == "m" then
            if i + 2 > #tokens then
                print("Error: Insufficient tokens for M command at index " .. i)
                break
            end
            local x = tonumber(tokens[i + 1])
            local y = tonumber(tokens[i + 2])
            if not x or not y then
                print("Error: Invalid numbers for M command at index " .. i .. ": x=" .. tostring(tokens[i + 1]) .. ", y=" .. tostring(tokens[i + 2]))
                break
            end
            if cmd == "m" then
                x = currentX + x
                y = currentY + y
            end
            table.insert(commands, {type = "M", x = x, y = y})
            currentX, currentY = x, y
            lastControlX, lastControlY = nil, nil
            i = i + 3
        elseif cmd == "L" or cmd == "l" then
            if i + 2 > #tokens then
                print("Error: Insufficient tokens for L command at index " .. i)
                break
            end
            local x = tonumber(tokens[i + 1])
            local y = tonumber(tokens[i + 2])
            if not x or not y then
                print("Error: Invalid numbers for L command at index " .. i .. ": x=" .. tostring(tokens[i + 1]) .. ", y=" .. tostring(tokens[i + 2]))
                break
            end
            if cmd == "l" then
                x = currentX + x
                y = currentY + y
            end
            table.insert(commands, {type = "L", x = x, y = y})
            currentX, currentY = x, y
            lastControlX, lastControlY = nil, nil
            i = i + 3
        elseif cmd == "C" or cmd == "c" then
            if i + 6 > #tokens then
                print("Error: Insufficient tokens for C command at index " .. i)
                break
            end
            local x1 = tonumber(tokens[i + 1])
            local y1 = tonumber(tokens[i + 2])
            local x2 = tonumber(tokens[i + 3])
            local y2 = tonumber(tokens[i + 4])
            local x = tonumber(tokens[i + 5])
            local y = tonumber(tokens[i + 6])
            if not x1 or not y1 or not x2 or not y2 or not x or not y then
                print("Error: Invalid numbers for C command at index " .. i .. ": x1=" .. tostring(tokens[i + 1]) .. ", y1=" .. tostring(tokens[i + 2]) .. ", x2=" .. tostring(tokens[i + 3]) .. ", y2=" .. tostring(tokens[i + 4]) .. ", x=" .. tostring(tokens[i + 5]) .. ", y=" .. tostring(tokens[i + 6]))
                break
            end
            if cmd == "c" then
                x1 = currentX + x1
                y1 = currentY + y1
                x2 = currentX + x2
                y2 = currentY + y2
                x = currentX + x
                y = currentY + y
            end
            table.insert(commands, {type = "C", x1 = x1, y1 = y1, x2 = x2, y2 = y2, x = x, y = y})
            currentX, currentY = x, y
            lastControlX, lastControlY = x2, y2
            i = i + 7
        elseif cmd == "S" or cmd == "s" then
            if i + 4 > #tokens then
                print("Error: Insufficient tokens for S command at index " .. i)
                break
            end
            local x2 = tonumber(tokens[i + 1])
            local y2 = tonumber(tokens[i + 2])
            local x = tonumber(tokens[i + 3])
            local y = tonumber(tokens[i + 4])
            if not x2 or not y2 or not x or not y then
                print("Error: Invalid numbers for S command at index " .. i .. ": x2=" .. tostring(tokens[i + 1]) .. ", y2=" .. tostring(tokens[i + 2]) .. ", x=" .. tostring(tokens[i + 3]) .. ", y=" .. tostring(tokens[i + 4]))
                break
            end
            local x1 = lastControlX and (currentX + (currentX - lastControlX)) or currentX
            local y1 = lastControlY and (currentY + (currentY - lastControlY)) or currentY
            if cmd == "s" then
                x2 = currentX + x2
                y2 = currentY + y2
                x = currentX + x
                y = currentY + y
            end
            table.insert(commands, {type = "C", x1 = x1, y1 = y1, x2 = x2, y2 = y2, x = x, y = y})
            currentX, currentY = x, y
            lastControlX, lastControlY = x2, y2
            i = i + 5
        elseif cmd == "H" or cmd == "h" then
            if i + 1 > #tokens then
                print("Error: Insufficient tokens for H command at index " .. i)
                break
            end
            local x = tonumber(tokens[i + 1])
            if not x then
                print("Error: Invalid number for H command at index " .. i .. ": x=" .. tostring(tokens[i + 1]))
                break
            end
            if cmd == "h" then
                x = currentX + x
            end
            table.insert(commands, {type = "L", x = x, y = currentY})
            currentX = x
            lastControlX, lastControlY = nil, nil
            i = i + 2
        elseif cmd == "V" or cmd == "v" then
            if i + 1 > #tokens then
                print("Error: Insufficient tokens for V command at index " .. i)
                break
            end
            local y = tonumber(tokens[i + 1])
            if not y then
                print("Error: Invalid number for V command at index " .. i .. ": y=" .. tostring(tokens[i + 1]))
                break
            end
            if cmd == "v" then
                y = currentY + y
            end
            table.insert(commands, {type = "L", x = currentX, y = y})
            currentY = y
            lastControlX, lastControlY = nil, nil
            i = i + 2
        elseif cmd == "Z" or cmd == "z" then
            table.insert(commands, {type = "Z"})
            lastControlX, lastControlY = nil, nil
            i = i + 1
        else
            print("Warning: Unrecognized command '" .. cmd .. "' at index " .. i)
            i = i + 1
        end
    end

    -- Debug: Log parsed commands
    if #commands == 0 then
        print("Warning: No commands parsed for path: " .. pathData)
    else
        print("Debug: Parsed " .. #commands .. " commands")
    end

    return commands
end
-- /Basic SVG support

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
        fillColor = "f8f9fa"
    })

    local startY = self.current_y + 20

    -- Draw bars
    for i, value in ipairs(barData) do
        local barHeight = (value / maxValue) * chartHeight
        local x = startX + (i-1) * (barWidth + 5) - 2
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

return PDFGenerator
