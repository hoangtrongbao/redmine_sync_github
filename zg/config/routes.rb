# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post '/zg_git_hook', to: 'git_hook#index'
post '/zg_git_oauth', to: 'git_hook#oauth'
