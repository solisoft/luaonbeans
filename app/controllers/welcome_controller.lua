local app = {
	index = function()
		Page("welcome/index", "app")
		-- or
		-- WriteJSON({ demo = true })
	end,

	pdf = function()
		PDFGenerator = require("pdfgenerator")

		local pdf = PDFGenerator.new({header_height = 50})
		-- Add a page (default A4 size)
		pdf:addPage()
		--pdf:addCustomFont("fonts/Helvetica.ttf", "helvetica", "normal")
		--pdf:addCustomFont("fonts/Helvetica-Bold.ttf", "helvetica", "bold")
		pdf:addCustomFont("fonts/TitilliumWeb-Regular.ttf", "titillium", "normal")
		pdf:addCustomFont("fonts/TitilliumWeb-Bold.ttf", "titillium", "bold")


		local headerColumns = {
			{ text = "Label", width = 305, fontSize = 10, alignment = "left", borderSides = { right = "false" }	},
			{ text = "UnitPrice", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false", right = "false" } },
			{ text = "Qty", width = 50, fontSize = 10, alignment = "center", borderSides = { left = "false", right = "false" } },
			{ text = "Total Price", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false" } }
		}

		local dataColumns = {}
		for i = 1, 100 do
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

		SetHeader("Content-Type", "application/pdf")
		Write(pdf:generate())
	end,
}

return HandleController(app)
