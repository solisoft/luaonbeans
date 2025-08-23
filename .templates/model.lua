return {
  all = function()
    return Adb.primary:Aql([[
      FOR ##model_singular## IN ##model_plural## SORT ##model_singular##._key ASC RETURN ##model_singular##
    ]]).result
  end,

  get = function(key)
    return Adb.primary:GetDocument("##model_plural##/" .. key)
  end,

  create = function(dataset)
    return Adb.primary:CreateDocument("##model_plural##", dataset)
  end,

  update = function(key, dataset)
    return Adb.primary:UpdateDocument("##model_plural##/" .. key, dataset)
  end,

  destroy = function(key)
    return Adb.primary:DeleteDocument("##model_plural##/" .. key)
  end
}
