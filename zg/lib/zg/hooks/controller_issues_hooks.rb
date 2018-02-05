module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_before_save(context = {})
        return unless context[:issue].project.sync_with_github?
        force_to_authorize unless User.current.authorized_github?
      end

      def controller_issues_new_after_save(context = {})
        return unless context[:issue].project.sync_with_github?
        return force_to_authorize unless User.current.authorized_github?
        github_adapter = Zg::GithubAdapter.new(context[:issue])
        github_adapter.create_issue
      end

      def controller_issues_edit_before_save(context = {})
        return unless context[:issue].project.sync_with_github?
        force_to_authorize unless User.current.authorized_github?
      end

      def controller_issues_edit_after_save(context = {})
        return unless context[:issue].project.sync_with_github?
        return force_to_authorize unless User.current.authorized_github?
        github_adapter = Zg::GithubAdapter.new(context[:issue])
        github_adapter.update_issue
        # User can add note(comment) when editing issue
        github_adapter.add_comment(context[:journal]) if context[:journal].notes.present?
      end

      private

      def force_to_authorize
        raise 'User is not authorized with Github'
      end
    end
  end
end
