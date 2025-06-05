return {
	action = HandleCronJob("*/3 * * * *", function()
		local t1 = GetTime()
		Log(kLogInfo, "\n" .. UuidV4())
		Log(kLogInfo, "\nThis runs every 3 minutes : " .. os.date("%Y-%m-%d %H:%M:%S"))
		Log(kLogInfo, "\nTime taken: " .. (GetTime() - t1))
	end)
}
