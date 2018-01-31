module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_after_save(context = {})
        github_adapter = Zg::GithubAdapter.new(context[:issue])
        github_adapter.create_issue
      end

      def controller_issues_edit_after_save(context = {})
        github_adapter = Zg::GithubAdapter.new(context[:issue])
        github_adapter.update_issue
        # User can add note(comment) when editing issue
        github_adapter.add_comment(context[:journal]) if context[:journal].notes.present?
      end
    end
  end
end
