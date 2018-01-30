module Zg
  module Hooks
    class ControllerJournalsHooks < Redmine::Hook::ViewListener
      def controller_journals_edit_post(context = {})
        journal = context[:journal]
        issue = context[:issue]
        repo = issue.project.ventura_project.git_repo_name
        github_adapter = Zg::GithubAdapter.new(repo)
        git_comment_id = journal.ventura_comment.git_comment_id
        if journal.destroyed?
          return github_adapter.delete_comment(git_comment_id)
        end
        github_adapter.update_comment(git_comment_id, journal.notes)
      end
    end
  end
end
