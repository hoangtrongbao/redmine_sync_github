require 'redmine'

Redmine::Plugin.register :zg do
  name 'Zigexn Github plugin'
  author 'Zigexn'
  description 'Github intergration for Redmine'
  version '0.0.1'
  url ''
  author_url ''
end

ActionDispatch::Callbacks.to_prepare do
  require 'zg'
end
