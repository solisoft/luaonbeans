return {
  up = function()
    local transaction = adb.BeginTransaction({
      writes = { "some", "tables" },
      reads = { "some", "tables" }
    })
    if(pcall(function()
      -- do something
    end)) then
      adb.CommitTransaction(transaction.result.id)
    else
      adb.AbortTransaction(transaction.result.id)
    end
  end,

  down = function()
    local transaction = adb.BeginTransaction({
      writes = { "some", "tables" },
      reads = { "some", "tables" }
    })
    if(pcall(function()
      -- do something
    end)) then
      adb.CommitTransaction(transaction.result.id)
    else
      adb.AbortTransaction(transaction.result.id)
    end
  end
}