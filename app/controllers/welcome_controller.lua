local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJSON({ demo = true })
	end,

	pdf = function()
		PDFGenerator = require("pdfgenerator")

		local pdf = PDFGenerator.new({header_height = 50})

		pdf:setHeader(function(pageId)
			pdf:addParagraph("Header - redbean.com PDF Generator - %s on %d" % { pageId, pdf:totalPage(self) }, { fontSize = 16, alignment = "left", newPage = false })
			pdf:drawLine(50, 842-50, 595 - 50, 842-50, 1)
		end)

		-- Add a page (default A4 size)
		pdf:addPage()
		--pdf:addCustomFont("fonts/Helvetica.ttf", "helvetica", "normal")
		--pdf:addCustomFont("fonts/Helvetica-Bold.ttf", "helvetica", "bold")
		pdf:addCustomFont("fonts/TitilliumWeb-Regular.ttf", "titillium", "normal")
		pdf:addCustomFont("fonts/TitilliumWeb-Bold.ttf", "titillium", "bold")


		local imgName = pdf:addImage(LoadAsset("greece.jpg"), 1600, 492, "jpeg")
		pdf:drawImage(imgName)

		pdf:moveY(10)

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
				{ text = "$700", width = 70, fontSize = 10, alignment = "right", vertical_alignment = "middle" },
				{ text = "2", width = 50, fontSize = 10, alignment = "center", vertical_alignment = "middle" },
				{ text = "$1400", width = 70, fontSize = 10, alignment = "right", vertical_alignment = "middle" }
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
			]], { fontSize = 10, alignment = "justify", fontWeight = "bold", color = "FF0000" })
		end


		pdf:addPage()
		-- Chart title
		pdf:addParagraph("PDF Chart Examples", { fontSize = 20, alignment = "center", fontWeight = "bold" })
		pdf:moveY(20)

		-- 1. Bar Chart
		pdf:addParagraph("1. Bar Chart - Monthly Sales", { fontSize = 16, alignment = "left", fontWeight = "bold" })
		pdf:moveY(10)

		for i = 1, 5 do

			local barData = {Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100, Rand64() % 100}
			local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
			local chartWidth = 555 - 100
			local chartHeight = 60
			local barWidth = chartWidth / #barData - 5
			local maxValue = 100
			local startX = 25


			-- Draw chart background
			pdf:drawRectangle({
				width = chartWidth + 40,
				height = chartHeight + 40 + 10,
				borderWidth = 1,
				borderColor = "cccccc",
				fillColor = "f8f9fa"
			})

			local startY = pdf.current_y + 20

			-- Draw bars
			for i, value in ipairs(barData) do
				local barHeight = (value / maxValue) * chartHeight
				local x = startX + (i-1) * (barWidth + 5) - 2
				local y = startY + chartHeight - barHeight

				-- Bar color based on value
				local color = value > 80 and "4CAF50" or (value > 60 and "FF9800" or "F44336")

				pdf:setX(x)
				pdf:setY(startY + chartHeight - barHeight)
				pdf:drawRectangle({
					width = barWidth,
					height = barHeight,
					borderWidth = 0.3,
					borderColor = "333333",
					fillColor = color,
				})

				-- Value label on top of bar
				pdf:setX(x)
				pdf:setY(startY + chartHeight - barHeight - 5)
				pdf:addText(tostring(value) .. " ", 8, "000000", "center", barWidth)

				-- Month label below bar
				pdf:setX(x)
				pdf:setY(startY + chartHeight + 10)
				pdf:addText(months[i] .. " 2025", 6, "000000", "center", barWidth)
				pdf:moveY(20)
			end

			pdf:setX(0)
			pdf:moveY(5)
		end

		SetHeader("Content-Type", "application/pdf")
		Write(pdf:generate())
	end,
}

return BeansEnv == "development" and HandleController(app) or app
