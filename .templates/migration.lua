return {
  up = function()
    local transaction = Adb.BeginTransaction({
      collections = {
        writes = { "some", "tables" },
        reads = { "some", "tables" },
      },
    })
    if
        pcall(function()
          assert(transaction.code == 201, "Transaction is not created")
          -- do something
        end)
    then
      Adb.CommitTransaction(transaction.result.id)
      return true
    else
      Adb.AbortTransaction(transaction.result.id)
      return false
    end
  end,

  down = function()
    local transaction = Adb.BeginTransaction({
      collections = {
        writes = { "some", "tables" },
        reads = { "some", "tables" },
      },
    })
    if
        pcall(function()
          assert(transaction.code == 201, "Transaction is not created")
          -- do something
        end)
    then
      Adb.CommitTransaction(transaction.result.id)
      return true
    else
      Adb.AbortTransaction(transaction.result.id)
      return false
    end
  end,
}
