local app = {
  -- GET welcome#index => /
  index = function()
    Page('welcome/index', 'app')
  end
}

return app[Params.action]()
