return {
  all = function()
    return adb.Aql([[
      FOR ##model_singular## IN ##model_plural## SORT ##model_singular##._key ASC RETURN ##model_singular##
    ]]).result
  end,

  get = function(key)
    return adb.GetDocument("##model_plural##/" .. key)
  end,

  create = function(dataset)
    return adb.CreateDocument("##model_plural##", dataset)
  end,

  update = function(key, dataset)
    return adb.UpdateDocument("##model_plural##/" .. key, dataset)
  end,

  destroy = function(key)
    return adb.DeleteDocument("##model_plural##/" .. key)
  end
}