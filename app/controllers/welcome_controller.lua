local app = {
  index = function()
    Page("welcome/index", "app")
    -- or
    -- WriteJSON({ demo = true })
  end,

  redis_incr = function()
    WriteJSON(Redis:incr("test"))
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
      { text = "Label", width = 305, fontSize = 10, alignment = "left", borderSides = { right = "false" }  },
      { text = "UnitPrice", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false", right = "false" } },
      { text = "Qty", width = 50, fontSize = 10, alignment = "center", borderSides = { left = "false", right = "false" } },
      { text = "Total Price", width = 70, fontSize = 10, alignment = "right", borderSides = { left = "false" } }
    }

    local dataColumns = {}
    for i = 1, 3 do
      table.insert(dataColumns, {
        { text = "demo " .. i, width = 305, fontSize = 10, alignment = "left", borderSides = { right = "false" } },
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
        { text = "Pro Morbi ultrices pharetra risus sed pellentesque. Integer id semper erat. Duis l" .. i, width = 305, fontSize = 10, alignment = "left" },
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
      pdf:BarChart(barData, months)
    end


    pdf:addPage()

    -- Next block
    pdf:moveY(10)
    pdf:drawSvgPath(500, 500, [[
     M344.2 794.3l-0.3-1.5-0.4-2.1-0.1-1.2 0-0.5 0.1-0.6 0.2-0.6 0.5-0.7 0.5-0.6 0.4-0.7 0.4-0.8 0-1.3 0-0.8-0.3-1.2-0.1-0.6 0.1-0.6 0.4-0.7 1.1-1.1 0.7-0.9 0.4-0.4 0.5-0.1 1.8-0.1 0.7-0.1 0.5-0.4 0.3-0.6-0.4-1.6-0.1-1 0.1-1.3 0.5-0.8 0.4-0.5 1.3-0.6 0.5-0.3 0.6-0.6 0.4-0.7 0.8-2.1 0.5-0.5 0.3-0.2 0.8 0.3 0.4-0.2 0.4-0.6 0.2-0.7 0.4-2 0.2-0.6 0.5-0.5 1-1 0.5-0.6 0.3-0.5 0.2-0.5 0-0.5-0.1-0.4-0.5-1.6 0-1.2 0.2-0.9 0.3-0.7 0.4-0.5 0.4-0.5 0.5-0.3 1.1-0.3 0.5-0.3 0.3-0.6-0.1-0.8-0.8-1.9-0.2-1.1 0.2-3.2-0.1-0.6-0.3-0.4-0.6 0-0.5 0.3-0.4 0.4-0.3 0.5-0.5 0.4-0.5 0-0.4-0.5-0.2-1.7 0.2-0.8 0.4-0.3 0.5 0.2 0.5 0 0.4-0.2 0.2-0.5-0.1-0.7-0.3-1-1.5-3.7-0.4-0.6-0.4-0.4-0.7-0.4-0.5-0.5-0.6-1.7-1.2-0.8-5.8-1.3-2.1 0.2-0.4-0.6-0.2-0.4-0.2-1-0.2-0.5-0.9-0.6 0-0.5 0.2-0.7 0.8-0.9 0.4-1-0.1-0.7-0.3-0.6-0.2-0.6 0.1-0.4 0.6-0.3 1 0 0.3-0.2 0.4-0.5 1.2-2.9 0.1-0.6-0.2-0.5-0.4-0.5-0.3-0.5 0-0.6 0.1-0.7 0-1.4 0.1-0.7 0.2-0.8 0.7-1.1 0.5-1.4 0-0.6-0.3-0.6-0.2-0.5-0.4-1.1-0.3-0.5-0.9-1-0.4-0.6 0.1-0.6 0.5-0.7 2.1-1.7 0.8-0.3 2.2 0.3 1.2 0 0.8-0.1 0.7-0.6 1.2-1.5 1.5-1.1 0.6-0.3 0.7-0.2 0.9 0.3 0.4 0.4 0.3 0.4 0.1 0.4 0 0.5-0.2 0.4-0.5 0.7-0.1 0.4 0 0.6 0.2 0.4 0.3 0.3 0.3 0.2 0.5 0.2 0.5 0.1 2.2 0.2 0.5-0.1 0.6-0.4 0.4-0.8 0.1-0.7-0.3-2.2 0.5-1 0.3-0.5 1.6-0.6 0.5-0.1 0.6 0.2 0.5 0.8 0.4 0.2 0.6-0.1 0.7-0.5 0.5-0.6 0.4-0.5 0.9-1.8 0.3-0.4 0.6-0.4 0.6-0.1 2.9 1.2 1.1 0.6 0.5 0.1 0.5 0 0.7-0.2 1.6-1.1 0.9-0.5 1.2-0.2 4.5-2.2 0.6-0.6 0.6-0.3 0.6-0.1 0.9 0.3 0.6 0.1 0.5 0 4.2-1.6 1-0.2 1.3 0.5 0.6 0.5 1.8 1.8 0.4 0.3 1.3-0.3 3.8-2.3 0.2-0.9 0.1-0.5 0.4-1.3 0.4-0.6 0.4-0.4 1.4-0.6 0.4-0.4 0.3-0.7 0.1-0.5 0.2-0.5 0.2-0.3 0.7-0.3 0.6 0 0.6 0.1 1 0.5 0.6 0.2 0.6 0 0.5-0.1 0.5-0.3 0.3-0.5 0-0.7-0.2-0.5-0.5-0.5-0.5-0.2-0.2-0.3 0-0.5 1.4-1 0.7-0.7 2.3-5.1 0.2-0.5 0.1-0.6-0.2-0.5-0.4-0.4-0.5-0.3-1.6-0.5-0.4-0.3-0.2-0.5-0.5-0.9 0.1-0.6 0.6-1.3 0.1-0.6 0.1-0.5 0-0.6 0-0.6 0-0.6 0.2-0.5 0.4-0.4 0.6-0.1 0.6 0.3 0.4 0.5 0.8 0.4 1.2 0.2 5.1-0.4 0.8-0.9 0-0.1 0.1-2.1 0.1-0.8 0-0.8-0.4-0.8-1-0.8-0.5-0.5-0.2-0.6-0.2-1.1-0.2-0.4-0.2-0.4-0.2-0.4-0.1-0.6 0.1-1.2-0.1-0.5-0.2-0.5-0.4-0.5-0.4-0.5-0.2-0.3-0.1-0.5 0.3-0.6 0.6-0.7 3-1.5 1-0.8 1.1-1 1.5-1.6 0.7-1 2.7-5 1-0.8 0.6-0.3 1.1-0.1 0.6-0.2 0.5-0.3 0.9-0.9 0.5-0.4 1.1-0.4 0.7-0.5 0.8-0.7 0.9-1.3 0.4-0.9 0.1-0.9-0.3-0.6-0.4-0.4-0.1-0.7 0.2-0.7 0.8-1.1 0.6-0.4 0.6-0.1 0.6 0 0.5-0.3 0.5-0.8 0.7-1.5 0.5-0.8 0.5-0.6 1.7-1.5 0.4-0.5 0.3-0.6 0-0.6-0.2-0.8 0-0.6 0.4-0.6 0.3-0.8 0.1-1-1.4-4.4 0.3-1.4 1.8-1.4 1-0.4 0.2-0.2 0.6-0.6 0.9-0.2 0.2-0.2 0.6-0.7 0.5-0.3 0.4 0 0.3 0.4 0.2 0.5 0.1 0.4 0.4 0.2 1.4-0.6 0.8-0.1 1.8 0.6 1 0.6 2 1.4 2.1 1.9 0.4 0.5 0.1 0.6 0.3 0.5 0.5 0.5 1.2 0.6 0.7 0.5 0.6 0.4 0.3 0.4 0.4 0.3 0.8 0.2 1.3 0 3.2-1.1 3.5-2 0.6-0.1 0.5 0 0.6 0.3 0.3 0.4 0.3 0.1 0.5 0 1.6-0.9 0.3-0.1 1.3-0.2 3.3-0.1 0.8 1.7 0.5 5.2 0.4 1.5 0.5 1.2 2.6 4.2 1 1.9 0.3 1 0.1 0.9-1 4.7-0.5 1.2-0.1 0.7 0.3 0.2 1 0.5 0.5 0.5 0.2 0.5 0.4 2.5 0.3 0.9 0.3 0.7 0.8 0.7 0.7 0.1 0.6-2.2 0.9-0.5 0.6 0 3.8-1.3 0.7-0.1 0.6 0.2 0.4 0.5 0.2 0.4 0.5 0.4 0.4 0 0.4-0.2 0.6-0.4 0.3-0.1 0.4 0 0.7 0.1 2.3 0 2-0.2 1.1-0.6 0.6-0.6 0.7-1.1 1.9-2.1 0.4-0.5 0.2-0.5 0.2-0.5 0.3-1.7 0.1-0.5 0.7-1.5 1.4-2 0.4-0.7 0.1-0.5 0.2-1.2 0.1-0.5 0.3-0.6 8.2-8.8 0.4 0.1 0.4 0.3 0.3 0.6 0.3 0.5 0.9 1 0.3 0.6 0.2 0.6 0.1 0.6 0 0.5-0.1 1.1 0.2 0.4 0.4 0.1 1.8-0.4 0.6 0 0.3 0.1 0.3 0.1 0.6 1.4 1.3 1.6 0.3 0.6 0.5 1.7 0.3 0.6 0.4 0.4 0.5 0.3 1.4 0.5 0.3 0.1 0.3 0.3 0.2 0.5-0.2 0.4-0.6 0.3-0.4 0.3-0.2 0.4 0.2 0.5 0.3 0.6 0.1 0.6 0.1 0.5 0.1 1.8 0.1 0.6 0.3 1.1 0.5 1.2 0.3 0.5 0.5 0.6 2 1.8 0.9-2.8 0.6-1.2 1.1-1.5 0.2-0.7 0.4-3 0.8-3.7 0.6-1.6 0.5-1.1 1.1-0.6 0.6-0.6 0.5-1.9 0.2-2 0.4-0.6 0.5-0.5 0.6-0.1 0.4 0.2 1 1.6 0.4 0.4 0.9-0.1 1.2-0.8 3.5-3.6 0.8-0.4 0.5 0.2 0.6 0 0.6-0.2 0.7-0.3 2.6-1.8 0.4-0.2 0.8-0.2 0.7 0.1 0.6-0.3 0.5 0.3 0.2 0.5 0.3 1.1 0.5 1.8 3.5 6.8 1.2 1.3 0.9 0.5 0.8-0.5 0.6-0.2 0.6-0.2 2.1-0.1 0.6-0.1 0.6-0.3 0.3-0.5 0.2-0.6 0.1-1.2 0.1-0.6 0.3-0.5 0.4-0.3 0.7-0.1 0.8-0.1 1.1 0.2 0.6 0.5 0.5 0.6 0.1 0.5-0.2 0.6-0.2 0.5-0.2 0.5 0.1 0.4 0.4 0.2 3.4 0.6 0.8 0.3 0.5 0.4 1.7 1.9 1.9 1.6 0.8 0.5 0.9 0.3 0.4 0.2 0.4 0.4 0.4 0.3 0.3 0.1 1.5 0.4-0.2 2.5 0.2 1.1 0.2 0.9 0.2 0.4 0.1 0.2 0.8 2.5 0.5 3.6 0.7 2.4 0.6 1.3 1.3 0.9 0.9 1.6 0.5 1.3 1.8 6.8 1.7 1.6 0.9 1.9 0.8 1.2 0.1 0.7-0.3 0.5-0.4 0.4-0.2 0.8 0.3 1.1 0.2 2.8 0.3 0.5 0.5 0.1 1.1-0.4 0.6 0 0.5 0.1 0.6 0 1.1-0.5 0.6 0.1 0.3 0.3 0.4 0.6 0.5 0.4 0.7 0.2 4.2 2.5 0.7 0.3 0.7 0 0.5-0.1 0.5-0.4 0.7-1 0.4-0.4 1.6-1 1.4-1.3 0.5-0.3 1.9-0.5 0.9 0.1 0.4 0.4 0.2 0.5-0.1 0.6-0.2 0.5 0 0.6 0.2 0.6 0.8 0.8 0.6 0.2 0.7-0.1 0.6-0.4 0.4-0.5 0.2-0.5 0.1-0.5 0-1.1 0.3-0.5 0.7-0.4 1.8-0.2 1.6 0.2 1.8 0.8 0.3 0.4 0.1 0.2 0.2 0.2 0.5 0.4 0.2 0.2 0.3 0.4 0.2 0.2 0.4 0.3 1.6 0.9 2.9 0.7 0.5 2.1 0.7 0.9 0.5 0.6 0.1 0.4 0.1 0.3-0.1 0.4 0 0.7 0.1 0.4 0.3 0.3 0.7 0.5 0.6 0.5 0.2 0.5 0.2 0.3 0.2 2.6 0 0.7-0.1 1.1-0.1 0.3-0.1 0.3 0 0.3-0.1 0.4 0.3 2.6 0.2 0.5 0.2 0.2 0.2 0 0.5-0.3 0.2-0.1 0.3 0 0.7 0 0.4 0.1 0.4 0.2 0.3 0.3 2.9 4 1.2 1.3 0.2 0.4 0.1 0.4 0 0.4 0 0.3-0.1 0.2-0.1 0.1 0 0.1-0.1 0-0.1 0-0.2 0.1-0.3-0.1-0.1 0-0.3-0.1-0.2 0-0.3 0.1 0 0.1 0 0.2 0 0.5 0.1 1.3 0 0.3-0.1 0.4-0.1 0.3-0.4 0.5-0.4 0.5-0.3 0.3-0.8 0.5-0.4 0.3-0.1 0.2-0.4 0.4-2.1 0.9-0.8 0.4-2.3 1.9-1.9 1.1-0.7 0.6-0.4 0.4-0.1 0.7 0.1 1 0.1 0.6 0.1 0.3 0.3 1.8 0 0.6 0 0.6-0.2 0.9-0.7 2.3-1.1 2.3-0.1 0.4 0 0.3 0.1 0.3 0.1 0.2 0 0.5-0.1 0.5-0.2 1-0.3 0.5-0.2 0.2-0.2 0-0.3 0-0.3-0.1-0.2-0.1-0.5-0.3-0.5-0.3-2-0.7-0.3 0-0.3 0-0.3 0.1-1.6 0.5-1.4 1.1-1.6 2.3-0.3 0.6-0.2 0.8-0.2 0.5-0.5 1.1-0.2 0.3 0 0.3 0.2 0.2 0.2 0.2 0.2 0.1 0.4 0.1 0.3 0 0.6 0 0.2 0.2 0 0.5-0.3 1.1-0.3 0.5-0.3 0.3-0.3 0-1.1 0.1-0.3 0.1-0.5 0.3-0.2 0.3-0.1 0.3 0 0.6-0.2 0.3-0.3 0.1-1.1 0.3-0.3 0.1-2.5 2.2-1 0.6-0.7 0.4-1.4 0.2-0.5 0.4-0.4 0.5-0.5 0.3-0.6 0-0.3 0.2-0.1 0.1-0.1 0 0 0.1-0.1 0.3-0.2 0.8-0.6 1.3-1.6 1-1.5-0.4-1.3-0.6-1.7-1.3-1-2 1-2-0.1-0.2-1.6-1.4-3.6-0.3-3.5 0.4-2.4 0.9-0.8 0.7-12.3 10.2-7.3 3.2-2 1.7-4.8 6.3-1.3 0.6-2.4-1.3-1.5 0.3-2.7 0.1-4.2 1.8-4.5 3.7-1 1.3-0.5 0.8-0.8 0.7-0.7 0.9-1.1 0.9-0.8 1.1-0.7 1.5-1.1 1.2-1.4 1.2-0.6 1.6-0.5 1.3-0.6 1.5-1 2.3-0.4 1.6-0.5 1.3-0.6 2.5-0.4 1.8 0.2 0.8 0.8 0.5 0 1.7-0.5 5-0.1 0.9-0.3 3.9-0.1 3.4 0.3 2.2-0.4 3.5 0.3 4.5 0.2 3.5 0.4 2.7 0.9 1.1 1.3 0.6 1.7 0.4 1.4 0.5 0.5 0.8 0 1-0.2 0.9 0.5 0.8 0.6 0.6 1 1.6 0.3 1.8 0 0.3-2.7 0.5-1.6 0-1.6-0.1-1.3-0.4-0.7-0.5-0.6-0.7-0.5-0.7-0.4-1-0.4-0.1-1.8 0-0.7-0.2-1 0.7-2-0.8-2.1 1.6-1 0.2-1.1 0-1 0.1-1 0.6-1.8 1.8-1 0.6-1.3 0.2-2.4-0.3-1.3 0.1-1.1 0.5-2.6 2.1-0.5 0.7 0.6 1.6 0.7 0.9 0.1 0.3-1.7 0.1-1.3-0.2-2.9-1-1.2 0-0.5 0.5-0.5 1.3-0.4 0.4-0.6 0.1-0.7-0.3-1.3-0.7-1.1-0.3-1.2-0.9-1-1.3-0.5-1.4-0.9 0-2-0.5-3.6-1.7-0.7-0.6-1.7-1-2 0.2-3.8 1.2-2.9-0.3-1 0.4-0.3 0.5-0.5 1.2-0.3 0.5-1.4 1.1-1.1 1.2-0.7 0.4-1 0.3-1.6 0.2-0.9-0.2-0.7-0.5-1.2-1-0.6-1.3-0.8-3.1-0.9-1.5-1-0.4-1.1 0-1.5-0.4-3.4-2.4-1.3-0.5-3.9-0.5-1.1-0.5 0-0.3 0-0.2-0.1-0.2-0.2-0.1 0.2-2.1 0.4-1 0.3-0.7 1.1-1.1 1.6-0.2-0.3-0.3-0.5-0.8-1.4-0.4-1-0.7 0.5-1.7-7-0.7-0.7-0.3-3.4-2.3-0.9 0.1-1.8 0.7-2-0.1-0.9 3.3-1.4 0.5-0.9-1.1-1.1-2.9-1.1-1.7-1.1-1.9-0.6-0.3-0.5-0.1-0.3-0.3 0.2-1.2-1.4-0.4-7.7 0-2 0.7-0.7-0.1-1.1-0.8-0.6-1.2-0.5-1.3-0.6-1.2-1.1-1-1.3-0.4-5.2-0.3-0.5-0.3-1-0.9-0.6-0.2-0.6 0.2-0.6 0.5-0.6 0.3-0.6-0.2-1-1-0.5-0.4-1.9-0.8-2.7-1.6-1-0.1-1.2 0.1-1.1-0.3-2.1-0.8-1.1-0.1-1.7 0.1-1.4 0.6-0.3 1.2 0.1 1.8-0.9 2.3 0.7 1-0.4 0.4-0.3 0.3-0.4 0.9 0.9 0.3 0.8 0.9 0.4 1.3-0.1 1.4-0.1 0.2-0.4 0.7-0.8 0.2-2.2-0.2-7.7 0.2-1.1-0.5-2.3 0.7-1.2 0-1.3-0.2-0.3-0.3 0-0.3 0-0.4-0.1-0.3-1.7-1.4-1.2 0.4-1.1 1.1-1.7 2.4-0.9 0.2-1-1.2-1.3-2.3-1-0.5-3.3-0.9-1 0.2-1.2 0.8-3.7 0.5-4.8 1.8-2.2 0.2-2.4-1-0.4-0.4-0.3-0.4-0.4-0.4-0.8-0.2-0.6-0.3-0.2-0.5-0.1-0.6-0.4-0.5-1-0.8-0.7-1.3-0.4-1.4 0.2-1.5-1.2 0.5-1.7 0.5-1.7-0.2-0.7-1.6-3.6-2.2z m139.3 31.9l0.9 0.7 1.4 0.2 0.1 0 0.7-0.2 0.2 0-0.7-1.2-0.6-1.4-0.7-0.9-0.7 0.3-0.7 1.5 0.1 1z m-124.6-78.2l0.2 0.4 0 0.5 0 0.6-0.1 0.7-0.5 1.2-0.2 0.3-0.2 0.2-0.2 0.2-0.2 0.1-0.6 0-0.6-0.3-0.4-0.6-0.2-0.9 0.2-1.7 0.3-0.8 0.5-0.6 0.4-0.1 0.3 0 0.8 0.2 0.3 0.3 0.2 0.3z m-3.2 11l-0.5-0.2-0.5-0.7-0.2-0.5 0-0.6 0.1-1.2 1.4-1.7 1.5 0.9 0.6 1.9-1.1 1.9-0.6 0.2-0.7 0z
      ]], {
        strokeColor = "000000", borderWidth = 1, align = "center", fillColor="cccccc"
    })

    pdf:moveY(500)
    pdf:drawLine(55, pdf:currentYPos(), 545, pdf:currentYPos(), 2, { color = "ff0000", style = "solid" })   -- red solid
    pdf:moveY(10)
    pdf:drawLine(55, pdf:currentYPos(), 545, pdf:currentYPos(), 2, { color = "0000ff", style = "dashed" }) -- blue dashed
    pdf:moveY(10)
    pdf:drawLine(55, pdf:currentYPos(), 545, pdf:currentYPos(), 1, { color = "00aa00", style = "dotted" }) -- green dotted
    pdf:moveY(10)
    pdf:drawLine(55, pdf:currentYPos(), 545, pdf:currentYPos(), 1, { color = "00aa00", style = "dotted", cap = "round"  }) -- green dotted
    pdf:moveY(10)
    pdf:drawLine(55, pdf:currentYPos(), 545, pdf:currentYPos(), 1, { color = "00aa00", style = "dashed", cap = "round"  }) -- green dotted

    SetHeader("Content-Type", "application/pdf")
    Write(pdf:generate())
  end,
}

return BeansEnv == "development" and HandleController(app) or app
