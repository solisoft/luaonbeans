return {
  action = HandleCronJob("*/3 * * * *", function()
    local t1 = GetTime()
    Log(kLogInfo, "\n" ..EncodeJson(Adb.Aql("RETURN UUID()").result))
    Log(kLogInfo, "\nThis runs every 3 minutes : " .. os.date("%Y-%m-%d %H:%M:%S"))
    Log(kLogInfo, "\nTime taken: " .. (GetTime() - t1))
    Log(kLogInfo, "\n--------" .. (GetTime() - t1))
  end)
}
