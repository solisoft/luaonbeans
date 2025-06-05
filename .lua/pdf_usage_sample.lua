PDFGenerator = require("pdfgenerator")

local pdf = PDFGenerator.new({header_height = 50})

pdf:setHeader(function(pageId)
	pdf:addParagraph("Header - redbean.com PDF Generator - %s on %d" % { pageId, pdf:totalPage(self) }, { fontSize = 16, alignment = "left", newPage = false })
	pdf:drawLine(50, 842-50, 595 - 50, 842-50, 1)
end)

-- Add a page (default A4 size)
pdf:addPage()

--pdf:addCustomFont("fonts/TitilliumWeb-Regular.ttf", "titillium", "normal")
--pdf:addCustomFont("fonts/TitilliumWeb-Bold.ttf", "titillium", "bold")

local imgName = pdf:addImage(LoadAsset("usa.jpeg"), 1567, 444, "jpeg")
pdf:drawImage(imgName)

-- Add some text
pdf:addParagraph([[
	Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
]], { fontSize = 15, alignment = "justify", fontWeight = "bold" })

pdf:moveY(10)

pdf:addParagraph([[
	Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
]], { fontSize = 15, alignment = "justify", fontWeight = "normal" })

pdf:moveY(10)

pdf:addParagraph([[
	Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
]], { fontSize = 10, alignment = "right" })

pdf:moveY(10)

pdf:addParagraph([[
	Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
]], { fontSize = 10, alignment = "center" })

pdf:moveY(10)

pdf:addParagraph([[
	Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
]], { fontSize = 10, alignment = "left" })

pdf:moveY(10)

local headerColumns = {
	{ text = "Label", width = 305, fontSize = 10, alignment = "left", borderSides = { right = "false" }	},
	{ text = "UnitPrice", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false", right = "false" } },
	{ text = "Qty", width = 50, fontSize = 10, alignment = "center", borderSides = { left = "false", right = "false" } },
	{ text = "Total Price", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false" } }
}

local dataColumns = {}
for i = 1, 3 do
	table.insert(dataColumns, {
		{ text = "Mac Mini M4 pro " .. i, width = 305, fontSize = 10, alignment = "left", borderSides = { right = "false" } },
		{ text = "$700", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false", right = "false" } },
		{ text = "2", width = 50, fontSize = 10, alignment = "center", borderSides = { left = "false", right = "false" } },
		{ text = "$1400", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false" } }
	})
end

pdf:drawTable({
	header_columns = headerColumns,
	data_columns = dataColumns,
	header_options = { fillColor = "eee", borderColor = "eee" },
	data_options = { fillColor = "fff", borderColor = "eee" }
}, { padding_x = 5, padding_y = 5 })

pdf:moveY(10)

local dataColumns = {}
for i = 1, 10 do
	table.insert(dataColumns, {
		{ text = "Mac Mini M4 pro Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis l" .. i, width = 305, fontSize = 10, alignment = "left" },
		{ text = "$700", width = 70, fontSize = 10, alignment = "right" },
		{ text = "2", width = 50, fontSize = 10, alignment = "center" },
		{ text = "$1400", width = 70, fontSize = 10, alignment = "right" }
	})
end

pdf:drawTable({
	header_columns = headerColumns,
	data_columns = dataColumns,
	header_options = { fillColor = "000", borderColor = "000", textColor = "fff" },
	data_options = { fillColor = "fff", borderColor = "eee", oddFillColor = "fafafa", evenFillColor = "fff" }
}, { padding_x = 5, padding_y = 2 })

for i = 1, 1 do
	pdf:moveY(10)
	pdf:addParagraph([[
		Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.

		Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis lobortis mollis erat, id commodo orci lobortis ut. Sed laoreet libero sed lorem sagittis, et lacinia arcu efficitur. Curabitur eu scelerisque elit. Aenean enim turpis, congue nec ipsum non, dapibus laoreet ex. Cras viverra congue tortor vitae rutrum.
	]], { fontSize = 10, alignment = "justify", fontWeight = "bold" })
end

SetHeader("Content-Type", "application/pdf")
Write(pdf:generate())
