module Zg
  module Hooks
    class ControllerJournalsHooks < Redmine::Hook::ViewListener
      def controller_journals_edit_post(context = {})
        return unless context[:journal].issue.project.sync_with_github?
        github_adapter = Zg::GithubAdapter.new(context[:journal].issue)
        if context[:journal].destroyed?
          return github_adapter.delete_comment(context[:journal])
        end
        github_adapter.update_comment(context[:journal])
      end
    end
  end
end
