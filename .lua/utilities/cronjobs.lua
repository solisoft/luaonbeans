local function ParseCronString(cronString)
	local parts = string.split(cronString, " ")
	if #parts ~= 5 then
		error("Invalid cron string format. Expected 5 parts.")
	end

	local cronParts = {
			minute = parts[1],
			hour = parts[2],
			dayOfMonth = parts[3],
			month = parts[4],
			dayOfWeek = parts[5]
	}

	local function parseField(field, min, max, date_field)
			if field == "*" then
				return true
			elseif field:match("^%*/(%d+)$") then
				local currentDate = os.date("*t", os.time())
				local interval = tonumber(field:match("^%*/(%d+)$"))
				return currentDate[date_field] % interval == 0
			else
				error("Invalid cron field: " .. field)
			end
	end

	return {
		minute = parseField(cronParts.minute, 0, 59, "min"),
		hour = parseField(cronParts.hour, 0, 23, "hour"),
		dayOfMonth = parseField(cronParts.dayOfMonth, 1, 31, "day"),
		month = parseField(cronParts.month, 1, 12, "month"),
		dayOfWeek = parseField(cronParts.dayOfWeek, 0, 6, "wday")
	}
end

local function ShouldRunCronJob(cronPattern, currentTime)
	return cronPattern.minute and
				 cronPattern.hour and
				 cronPattern.dayOfMonth and
				 cronPattern.month and
				 cronPattern.dayOfWeek
end

local function HandleCronJob(cronString, jobFunction)
	local cronPattern = ParseCronString(cronString)
	local currentTime = os.time()

	if ShouldRunCronJob(cronPattern, currentTime) then
		jobFunction()
	end
end

return {
	HandleCronJob = HandleCronJob
}
