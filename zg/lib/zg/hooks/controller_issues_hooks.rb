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

      # rubocop:disable Metrics/AbcSize
      def controller_issues_edit_after_save(context = {})
        journal = context[:journal]
        issue = context[:issue]
        repo = issue.project.ventura_project.git_repo_name
        github_adapter = Zg::GithubAdapter.new(repo)
        git_id = issue.ventura_issue.git_issue_id
        github_adapter.update_issue(git_id,
                                    issue.subject,
                                    issue.description)
        if journal.notes.present?
          git_comment = github_adapter.add_comment(git_id,
                                                   journal.notes)
          journal.build_ventura_comment(git_comment_id: git_comment['id']).save
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
