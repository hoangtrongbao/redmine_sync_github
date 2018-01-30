module Zg
  module Hooks
    class ViewProjectHooks < Redmine::Hook::ViewListener
      render_on :view_projects_form, partial: 'projects/git_repo'
      render_on :view_projects_show_right, partial: 'projects/zg_notify'
    end
  end
end
