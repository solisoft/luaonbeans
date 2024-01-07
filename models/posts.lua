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
    return adb.CreateDocument("posts", datasets)
  end,

  update = function(key, dataset)
    return adb.UpdateDocument("posts/" .. key, dataset)
  end,

  destroy = function(key)
    -- Remove associated comments
    adb.Aql([[
      FOR comment IN comments FILTER comment.post_id == TO_STRING(@key)
        REMOVE comment IN comments
    ]], { key = key })
    return adb.DeleteDocument("posts/" .. key)
  end
}