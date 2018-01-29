module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        repo = issue.project.ventura_project.git_repo_name
        github_adapter = Zg::GithubAdapter.new(repo)
        git_issue = github_adapter.create_issue(issue.subject, issue.description)
        VenturaIssue.create(issue: issue, git_issue_id: git_issue['id'])
      end
    end
  end
end
