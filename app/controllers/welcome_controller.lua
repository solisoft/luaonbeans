local app = {
  -- GET customers#index => /
  index = function()
    Page('welcome/index', 'app')
  end,
  ban = function()
    WriteJSON(Params)
  end
}

return app[Params.action]()
