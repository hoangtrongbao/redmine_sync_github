module Zg
  module Hooks
    class ViewProjectHooks < Redmine::Hook::ViewListener
      render_on :view_my_account, partial: 'my/github_status'
    end
  end
end
