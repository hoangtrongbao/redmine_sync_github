module Zg
  module Hooks
    class ControllerIssuesHooks < Redmine::Hook::ViewListener
      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        client = Octokit::Client.new(login: '',
                                     password: '')

        client.create_issue('hoangphucd3/test_jenkins',
                            issue.subject,
                            issue.description)
      end
    end
  end
end
