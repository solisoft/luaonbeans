if GetMethod() == "POST" then
	--SetStatus(301)
	--SetHeader('Location', '/')
	--return
end

-- prepare the dataset
local per_page = 30
local current_page = tonumber(GetParam('page')) or 1

local dataset = Aql(
	[[
		LET c = LENGTH(transactions)
		LET results = (FOR t IN transactions LIMIT @offset, @count RETURN { _key: t._key })
		RETURN { count: c, transactions: results }
	]],
	{
		count = per_page,
		offset = (current_page - 1) * per_page
	}
)

local total_pages = dataset.result[1].count / per_page

-- Display the page with a specific layout
Write(
	F.Page(
		"signin", -- view
		"app", -- layout
		{ -- view bindVars
			dataset = dataset,
			per_page = per_page,
			total_pages = total_pages,
			current_page = current_page
		},
		{ -- layout bindVars
			title = "V2 is coming"
		}
	)
)

