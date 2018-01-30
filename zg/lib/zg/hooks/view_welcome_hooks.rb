module Zg
  module Hooks
    class ViewWelcomeHooks < Redmine::Hook::ViewListener
      # render_on :view_welcome_index_left, partial: 'welcome/oauth'
    end
  end
end
