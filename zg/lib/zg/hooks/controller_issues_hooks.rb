module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        user = User.current
        oauth_token = user.ventura_user.oauth_token
        client = Octokit::Client.new(access_token: oauth_token)
        git_issue = client.create_issue('phucdh/test_redmine',
                                        issue.subject,
                                        issue.description)
        VenturaIssue.create(issue: issue, git_issue_id: git_issue['id'])
      end
    end
  end
end
