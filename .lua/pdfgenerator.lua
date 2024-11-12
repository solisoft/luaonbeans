-- PDF Generator Library for PDF 1.7
local PDFGenerator = {}

-- PDF object counter
local objCounter = 1

-- Utility function to get new object number
local function getNewObjNum()
    local num = objCounter
    objCounter = objCounter + 1
    return num
end

-- Convert number to PDF string format
local function numberToString(num)
    return string.format("%.2f", num)
end

-- Create new PDF document
function PDFGenerator.new()
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
        header_height = 50,
        margin_x = {50, 50},
        margin_y = {50, 80},
        current_x = 0,
        current_y = 0,
        resources = {},
        font_metrics = {},
        current_table = {
            current_row = {
                height = nil
            },
            padding = 5,
            header_columns = nil,
            data_columns = nil,
            header_options = nil,
            data_options = nil
        },
        out_of_page = false,
    }

    self.header = function(pageId) end
    self.footer = function(pageId)
        self.moveY(self, 5)
        self:addParagraph("Page %s of %s" % { pageId, #self.page_list }, { fontSize = 8, alignment = "right" })
    end

    -- Initialize document
    self.info = getNewObjNum()
    self.root = getNewObjNum()
    self.pages_obj = getNewObjNum()

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
    width = width or 595    -- Default A4 width in points
    height = height or 842  -- Default A4 height in points

    local pageObj = getNewObjNum()
    local contentObj = getNewObjNum()

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
        "%d 0 obj\n<< /Type /Page /Parent %d 0 R /Contents %d 0 R /MediaBox [0 0 %s %s] /Resources << /Font << /F1 %d 0 R >> /XObject << >> >> >>\nendobj\n",

        pageObj,
        self.pages_obj,
        contentObj,
        numberToString(width),
        numberToString(height),
        self:addBasicFont()
    )

    --self:drawHeader()
    --self:drawFooter()

    self:setY(0)
    self:setX(0)

    -- Display table header
    if self.current_table.header_columns then
        self:drawRowTable(self.current_table.header_columns, { fillColor = "eee" })
    end

    return self
end

-- Add basic Helvetica font
function PDFGenerator:addBasicFont()
    local fontObj = getNewObjNum()
    self.objects[fontObj] = string.format(
        "%d 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n",
        fontObj
    )
    return fontObj
end

-- Add custom font (TrueType)
function PDFGenerator:addCustomFont(fontPath, fontName)
    local fontObj = getNewObjNum()
    local fontFileObj = getNewObjNum()
    local fontDescObj = getNewObjNum()

    -- Read font file
    local file = io.open(fontPath, "rb")
    if not file then
        error("Could not open font file: " .. fontPath)
    end
    local fontData = file:read("*all")
    file:close()

    -- Font descriptor object
    self.objects[fontDescObj] = string.format(
        "%d 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /%s /Flags 32 /FontBBox [-250 -250 1250 1250] /ItalicAngle 0 /Ascent 750 /Descent -250 /CapHeight 750 /StemV 80 /FontFile2 %d 0 R >>\nendobj\n",
        fontDescObj,
        fontName,
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
        "%d 0 obj\n<< /Type /Font /Subtype /TrueType /BaseFont /%s /FirstChar 32 /LastChar 255 /Encoding /WinAnsiEncoding /FontDescriptor %d 0 R  >>\nendobj\n",
        fontObj,
        fontName,
        fontDescObj
    )

    -- Add to resources
    if not self.custom_fonts then
        self.custom_fonts = {}
    end
    self.custom_fonts[fontName] = fontObj

    return fontObj
end

-- Use custom font for text
function PDFGenerator:useFont(fontName)
    if not self.custom_fonts or not self.custom_fonts[fontName] then
        error("Font not loaded: " .. fontName)
    end

    -- Store the current font name to be used in addText
    self.current_font = fontName

    -- Update the page's resources to include the custom font
    local pageObj = self.current_page_obj
    self.objects[pageObj] = self.objects[pageObj]:gsub(
        "(/Font << /F1 %d+ 0 R >>)",
        string.format("/Font << /F1 %d 0 R /%s %d 0 R >>",
            self:addBasicFont(),
            fontName,
            self.custom_fonts[fontName]
        )
    )

    return self
end
-- Get text width for current font and size using font metrics
function PDFGenerator:getTextWidth(text, fontSize, fontWeight)
    fontSize = fontSize or 12
    fontWeight = fontWeight or "normal"

    -- Helvetica character widths (in 1/1000 units of font size)
    -- These metrics are from the Adobe Font Metrics (AFM) file for Helvetica
    -- Values represent character widths in 1/1000 units of the font size
    local helveticaMetrics = {
        normal = {
            [32]=278, [33]=278, [34]=355, [35]=556, [36]=556, [37]=889, [38]=667, [39]=191, [40]=333, [41]=333,
            [42]=389, [43]=584, [44]=278, [45]=333, [46]=278, [47]=278, [48]=556, [49]=556, [50]=556, [51]=556,
            [52]=556, [53]=556, [54]=556, [55]=556, [56]=556, [57]=556, [58]=278, [59]=278, [60]=584, [61]=584,
            [62]=584, [63]=556, [64]=1015, [65]=667, [66]=667, [67]=722, [68]=722, [69]=667, [70]=611, [71]=778,
            [72]=722, [73]=278, [74]=500, [75]=667, [76]=556, [77]=833, [78]=722, [79]=778, [80]=667, [81]=778,
            [82]=722, [83]=667, [84]=611, [85]=722, [86]=667, [87]=944, [88]=667, [89]=667, [90]=611, [91]=278,
            [92]=278, [93]=278, [94]=469, [95]=556, [96]=333, [97]=556, [98]=556, [99]=500, [100]=556, [101]=556,
            [102]=278, [103]=556, [104]=556, [105]=222, [106]=222, [107]=500, [108]=222, [109]=833, [110]=556,
            [111]=556, [112]=556, [113]=556, [114]=333, [115]=500, [116]=278, [117]=556, [118]=500, [119]=722,
            [120]=500, [121]=500, [122]=500, [123]=334, [124]=260, [125]=334, [126]=584, [127]=350,
            -- Extended ASCII characters (128-255)
            -- These values are verified from the official Helvetica AFM specification
            [128]=556, [129]=350, [130]=222, [131]=556, [132]=333, [133]=1000, [134]=556, [135]=556,
            [136]=333, [137]=1000, [138]=667, [139]=333, [140]=1000, [141]=350, [142]=611, [143]=350,
            [144]=350, [145]=222, [146]=222, [147]=333, [148]=333, [149]=350, [150]=556, [151]=1000,
            [152]=333, [153]=1000, [154]=500, [155]=333, [156]=944, [157]=350, [158]=500, [159]=667,
            [160]=278, [161]=333, [162]=556, [163]=556, [164]=556, [165]=556, [166]=260, [167]=556,
            [168]=333, [169]=737, [170]=370, [171]=556, [172]=584, [173]=333, [174]=737, [175]=333,
            [176]=400, [177]=584, [178]=333, [179]=333, [180]=333, [181]=556, [182]=537, [183]=278,
            [184]=333, [185]=333, [186]=365, [187]=556, [188]=834, [189]=834, [190]=834, [191]=611,
            [192]=667, [193]=667, [194]=667, [195]=667, [196]=667, [197]=667, [198]=1000, [199]=722,
            [200]=667, [201]=667, [202]=667, [203]=667, [204]=278, [205]=278, [206]=278, [207]=278,
            [208]=722, [209]=722, [210]=778, [211]=778, [212]=778, [213]=778, [214]=778, [215]=584,
            [216]=778, [217]=722, [218]=722, [219]=722, [220]=722, [221]=667, [222]=667, [223]=611,
            [224]=556, [225]=556, [226]=556, [227]=556, [228]=556, [229]=556, [230]=889, [231]=500,
            [232]=556, [233]=556, [234]=556, [235]=556, [236]=278, [237]=278, [238]=278, [239]=278,
            [240]=556, [241]=556, [242]=556, [243]=556, [244]=556, [245]=556, [246]=556, [247]=584,
            [248]=611, [249]=556, [250]=556, [251]=556, [252]=556, [253]=500, [254]=556, [255]=500
        },
        bold = {
            [32]=278, [33]=333, [34]=474, [35]=556, [36]=556, [37]=889, [38]=722, [39]=238, [40]=333, [41]=333,
            [42]=389, [43]=584, [44]=278, [45]=333, [46]=278, [47]=278, [48]=556, [49]=556, [50]=556, [51]=556,
            [52]=556, [53]=556, [54]=556, [55]=556, [56]=556, [57]=556, [58]=333, [59]=333, [60]=584, [61]=584,
            [62]=584, [63]=611, [64]=975, [65]=722, [66]=722, [67]=722, [68]=722, [69]=667, [70]=611, [71]=778,
            [72]=722, [73]=278, [74]=556, [75]=722, [76]=611, [77]=833, [78]=722, [79]=778, [80]=667, [81]=778,
            [82]=722, [83]=667, [84]=611, [85]=722, [86]=667, [87]=944, [88]=667, [89]=667, [90]=611, [91]=333,
            [92]=278, [93]=333, [94]=584, [95]=556, [96]=333, [97]=556, [98]=611, [99]=556, [100]=611, [101]=556,
            [102]=333, [103]=611, [104]=611, [105]=278, [106]=278, [107]=556, [108]=278, [109]=889, [110]=611,
            [111]=611, [112]=611, [113]=611, [114]=389, [115]=556, [116]=333, [117]=611, [118]=556, [119]=778,
            [120]=556, [121]=556, [122]=500, [123]=389, [124]=280, [125]=389, [126]=584, [127]=350,
            [128]=556, [129]=350, [130]=278, [131]=556, [132]=500, [133]=1000, [134]=556, [135]=556,
            [136]=333, [137]=1000, [138]=667, [139]=333, [140]=1000, [141]=350, [142]=611, [143]=350,
            [144]=350, [145]=278, [146]=278, [147]=500, [148]=500, [149]=350, [150]=556, [151]=1000,
            [152]=333, [153]=1000, [154]=556, [155]=333, [156]=944, [157]=350, [158]=500, [159]=667,
            [160]=278, [161]=333, [162]=556, [163]=556, [164]=556, [165]=556, [166]=280, [167]=556,
            [168]=333, [169]=737, [170]=370, [171]=556, [172]=584, [173]=333, [174]=737, [175]=333,
            [176]=400, [177]=584, [178]=333, [179]=333, [180]=333, [181]=611, [182]=556, [183]=278,
            [184]=333, [185]=333, [186]=365, [187]=556, [188]=834, [189]=834, [190]=834, [191]=611,
            [192]=722, [193]=722, [194]=722, [195]=722, [196]=722, [197]=722, [198]=1000, [199]=722,
            [200]=667, [201]=667, [202]=667, [203]=667, [204]=278, [205]=278, [206]=278, [207]=278,
            [208]=722, [209]=722, [210]=778, [211]=778, [212]=778, [213]=778, [214]=778, [215]=584,
            [216]=778, [217]=722, [218]=722, [219]=722, [220]=722, [221]=667, [222]=667, [223]=611,
            [224]=556, [225]=556, [226]=556, [227]=556, [228]=556, [229]=556, [230]=889, [231]=556,
            [232]=556, [233]=556, [234]=556, [235]=556, [236]=278, [237]=278, [238]=278, [239]=278,
            [240]=611, [241]=611, [242]=611, [243]=611, [244]=611, [245]=611, [246]=611, [247]=584,
            [248]=611, [249]=611, [250]=611, [251]=611, [252]=611, [253]=556, [254]=611, [255]=556
        }
    }

    local width = 0
    for i = 1, #text do
        local charCode = string.byte(text, i)
        local metrics = helveticaMetrics[fontWeight]
        width = width + (metrics[charCode] or 556) -- default to 556 for unknown chars
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
        local wordWidth = self:getTextWidth(word, fontSize)
        local spaceWidth = self:getTextWidth(" ", fontSize)

        --Logger("word %s, wordWidth %s, spaceWidth %s" % { word, wordWidth, spaceWidth })

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
    local fontName = self.current_font or "F1"  -- Use current_font if set, otherwise fallback to F1

    -- Calculate x position based on alignment
    local x_pos = self.margin_x[1] + self.current_x
    local text_width = self:getTextWidth(text, fontSize)

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

-- Draw a table
function PDFGenerator:drawTable(options)
    options = options or {}
    self.current_table.header_columns = options.header_columns
    self.current_table.data_columns = options.data_columns
    self.current_table.header_options = options.header_options
    self.current_table.data_options = options.data_options

    self:drawRowTable(options.header_columns, options.header_options)
    for _, column in ipairs(options.data_columns) do
        self:drawRowTable(column, options.data_options)
    end

    self.current_table.header_columns = nil
    self.current_table.data_columns = nil
    self.current_table.header_options = nil
    self.current_table.data_options = nil
    self.current_table.current_row = { height = nil, padding = 5}
end

-- Calculate maximum height needed for a collection of text items
function PDFGenerator:calculateMaxHeight(items)
    local max_height = 0

    for _, item in ipairs(items) do
        -- Ensure required fields exist
        local text = item.text or ""
        local fontSize = item.fontSize or 12
        local width = item.width or (self.page_width - self.margin_x[1] - self.margin_x[2])
        local padding = item.padding or self.current_table.padding or 5

        -- Split text into lines considering the available width
        local lines = self:splitTextToLines(text, fontSize, width - (padding * 2))

        -- Calculate height for this item
        local line_height = fontSize * 1.5  -- Standard line height
        local text_height = #lines * line_height + 2 -- + (padding * 2)  -- Include padding
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
    options.borderWidth = options.borderWidth or 1
    options.alignment = options.alignment or "left"
    options.fillColor = options.fillColor or "fff"
    options.borderColor = options.borderColor or "000"

    -- Draw cell border using existing rectangle method
    self:drawRectangle(
        options.width,
        self.current_table.current_row.height,
        options.borderWidth,
        "solid",
        options.borderColor,
        options.fillColor
    )

    -- Save current position before drawing text
    local saved_x = self.current_x
    local saved_y = self.current_y

    if options.alignment == "left" then
        self:moveX(self.current_table.padding)
    elseif options.alignment == "right" then
        self:moveX(-self.current_table.padding)
    end

    self:addParagraph(text, { fontSize = options.fontSize, alignment = options.alignment, width = options.width })

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

-- Add paragraph to current page
function PDFGenerator:addParagraph(text, options)
    options = options or {}
    options.fontSize = options.fontSize or 12
    options.alignment = options.alignment or "left"
    options.width = options.width or (self.page_width - self.margin_x[1] - self.margin_x[2])
    options.color = options.color or "000000"
    options.width = options.width

    local lines = self:splitTextToLines(text, options.fontSize, options.width)
    for i, line in ipairs(lines) do
        self.current_y = self.current_y + options.fontSize*1.2
        if self.out_of_page == false and self.page_height - self.current_y - self.header_height < self.margin_y[1] + self.margin_y[2] then
            self:addPage()
        end
        self:addText(line, options.fontSize, options.color, options.alignment, options.width)
    end
    return self
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
-- borderStyle can be "solid" or "dashed"
-- borderColor and fillColor should be in format {r, g, b} where each value is between 0 and 1
function PDFGenerator:drawRectangle(width, height, borderWidth, borderStyle, borderColor, fillColor)
    borderWidth = borderWidth or 1
    borderStyle = borderStyle or "solid"
    borderColor = borderColor or "000000"  -- default gray
    borderColor = PDFGenerator:hexToRGB(borderColor)
    fillColor = fillColor or "ffffff"  -- default gray
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

    -- Set line width
    content.stream = content.stream .. string.format("%s w\n", numberToString(borderWidth))

    -- Set dash pattern if needed
    if borderStyle == "dashed" then
        content.stream = content.stream .. "[3 3] 0 d\n"
    end

    -- If fill color is provided, set it and draw filled rectangle
    content.stream = content.stream .. string.format(
        "%s %s %s rg\n",
        numberToString(fillColor[1]),
        numberToString(fillColor[2]),
        numberToString(fillColor[3])
    )
    -- Draw filled and stroked rectangle
    content.stream = content.stream .. string.format(
        "%s %s %s %s re\nB\n",
        numberToString(self.margin_x[1] + self.current_x),
        numberToString(self.currentYPos(self) - height),
        numberToString(width),
        numberToString(height)
    )

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
