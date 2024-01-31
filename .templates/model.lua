return {
  all = function()
    return Adb.Aql([[
      FOR ##model_singular## IN ##model_plural## SORT ##model_singular##._key ASC RETURN ##model_singular##
    ]]).result
  end,

  get = function(key)
    return Adb.GetDocument("##model_plural##/" .. key)
  end,

  create = function(dataset)
    return Adb.CreateDocument("##model_plural##", dataset)
  end,

  update = function(key, dataset)
    return Adb.UpdateDocument("##model_plural##/" .. key, dataset)
  end,

  destroy = function(key)
    return Adb.DeleteDocument("##model_plural##/" .. key)
  end
}
