module Zg
  module Hooks
    class ViewProjectHooks < Redmine::Hook::ViewListener
      render_on :view_projects_form, partial: 'projects/git_repo'
    end
  end
end
