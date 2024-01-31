return {
  all = function()
    return Adb.Aql([[
      FOR post IN posts FILTER post._key == TO_STRING(@key)
      LET comments = (
        FOR comment IN comments FILTER comment.post_key == post._key
        SORT comment._key ASC RETURN comment
      )
      RETURN { post, comments }
    ]], { key = Params.post_id }).result[1]
  end,

  get = function(key)
    return Adb.GetDocument("comments/" .. key)
  end,

  create = function(dataset)
    return Adb.CreateDocument("comments", dataset)
  end,

  update = function(key, dataset)
    return Adb.UpdateDocument("comments/" .. key, dataset)
  end,

  destroy = function(key)
    return Adb.DeleteDocument("comments/" .. key)
  end
}
