module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_after_save(context = {})
        issue = context[:issue]
        repo = issue.project.ventura_project.git_repo_name
        github_adapter = Zg::GithubAdapter.new(repo)
        git_issue = github_adapter.create_issue(issue.subject, issue.description)
        issue.build_ventura_issue(git_issue_id: git_issue['number']).save
      end

      def controller_issues_edit_after_save(context = {})
        journal = context[:journal]
        issue = context[:issue]
        repo = issue.project.ventura_project.git_repo_name
        github_adapter = Zg::GithubAdapter.new(repo)
        git_comment = github_adapter.add_comment(issue.ventura_issue.git_issue_id,
                                                 journal.notes)
        journal.build_ventura_comment(git_comment_id: git_comment['id']).save
      end
    end
  end
end
