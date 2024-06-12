local app = {
  -- GET customers#index => /
  index = function()
    Page('welcome/index', 'app')
  end
}

return app[Params.action]()
