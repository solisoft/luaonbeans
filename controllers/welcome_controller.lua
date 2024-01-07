local app = {
  -- GET welcome#index => /posts
  index = function() Page('welcome/index', 'app') end
}

app[params.action]()

