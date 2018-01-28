require 'redmine'

Redmine::Plugin.register :zg do
  name 'Zigexn Github plugin'
  author 'Zigexn'
  description 'Github intergration for Redmine'
  version '0.0.1'
  url ''
  author_url ''

  # menu :account_menu,
  #      :zg,
  #      { controller: 'user_oauth', action: 'index'},
  #      caption: 'Github OAuth'
end

# project_module :zg do
#
# end

ActionDispatch::Callbacks.to_prepare do
  require 'zg/hooks/controller_issues_hooks'
  require 'zg/hooks/view_welcome_hooks'
end
