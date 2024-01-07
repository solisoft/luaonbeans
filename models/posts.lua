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
    adb.CreateDocument("posts", datasets)
  end,

  update = function(key, dataset)
    adb.UpdateDocument("posts/" .. key, dataset)
  end,

  destroy = function(key)
    adb.DeleteDocument("posts/" .. key)
  end
}