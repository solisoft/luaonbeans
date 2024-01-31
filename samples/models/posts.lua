return {
  all = function()
    return Adb.Aql([[
      FOR post IN posts SORT post._key ASC RETURN post
    ]]).result
  end,

  get = function(key)
    return Adb.GetDocument("posts/" .. key)
  end,

  create = function(dataset)
    return Adb.CreateDocument("posts", dataset)
  end,

  update = function(key, dataset)
    return Adb.UpdateDocument("posts/" .. key, dataset)
  end,

  destroy = function(key)
    -- Remove associated comments
    Adb.Aql([[
      FOR comment IN comments FILTER comment.post_id == TO_STRING(@key)
        REMOVE comment IN comments
    ]], { key = key })
    return Adb.DeleteDocument("posts/" .. key)
  end
}
