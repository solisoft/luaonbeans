return {
  all = function()
    return adb.Aql([[
      FOR post IN posts SORT post._key ASC RETURN post
    ]]).result
  end,

  get = function(key)
    return adb.GetDocument("posts/" .. key)
  end,

  create = function(dataset)
    return adb.CreateDocument("posts", dataset)
  end,

  update = function(key, dataset)
    return adb.UpdateDocument("posts/" .. key, dataset)
  end,

  destroy = function(key)
    return adb.DeleteDocument("posts/" .. key)
  end
}