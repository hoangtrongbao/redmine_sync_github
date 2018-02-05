module Zg
  module Hooks
    class ControllerJournalsHooks < Redmine::Hook::ViewListener
      # rubocop:disable Metrics/AbcSize
      def controller_journals_edit_post(context = {})
        return unless context[:journal].issue.project.sync_with_github?
        return force_to_authorize unless User.current.authorized_github?
        github_adapter = Zg::GithubAdapter.new(context[:journal].issue)
        if context[:journal].destroyed?
          return github_adapter.delete_comment(context[:journal])
        end
        github_adapter.update_comment(context[:journal])
      end
      # rubocop:enable Metrics/AbcSize

      private

      def force_to_authorize
        raise 'User is not authorized with Github'
      end
    end
  end
end
