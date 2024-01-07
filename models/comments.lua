return {
  all = function()
    return adb.Aql([[
      FOR post IN posts FILTER post._key == TO_STRING(@key)
      LET comments = (
        FOR comment IN comments FILTER comment.post_key == post._key
        SORT comment._key ASC RETURN comment
      )
      RETURN { post, comments }
    ]], { key = params.post_id }).result[1]
  end,

  get = function(key)
    return adb.GetDocument("comments/" .. key)
  end,

  create = function(dataset)
    adb.CreateDocument("comments", datasets)
  end,

  update = function(key, dataset)
    adb.UpdateDocument("comments/" .. key, dataset)
  end,

  destroy = function(key)
    adb.DeleteDocument("comments/" .. key)
  end
}