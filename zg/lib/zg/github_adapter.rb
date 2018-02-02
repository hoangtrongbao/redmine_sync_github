module Zg
  class GithubAdapter
    attr_accessor :api_client, :issue, :repo, :git_issue_number

    ACCESS_TOKEN_NAME = 'Ventura Redmine'.freeze

    def initialize(issue)
      @api_client = Octokit::Client.new(access_token: User.current.ventura_user.oauth_token)
      @issue = issue
      @repo = issue.project.git_repo_name
      @git_issue_number = issue.git_issue_number
    end

    def self.create_access_token(username, password)
      client = Octokit::Client.new(login: username, password: password)
      git_user = client.user
      access_token = client.create_authorization(scopes: %w[repo],
                                                 note: ACCESS_TOKEN_NAME)
      VenturaUser.create(user: User.current,
                         git_login: git_user[:login],
                         git_login_id: git_user[:id],
                         oauth_id: access_token[:id],
                         oauth_token: access_token[:token])
      true
    end

    def create_issue
      git_issue = api_client.create_issue(repo, issue.subject, issue.description)
      issue.build_ventura_issue(git_issue_number: git_issue['number'], git_issue_id: git_issue['id']).save
    end

    def update_issue
      api_client.update_issue(repo, git_issue_number, issue.subject, issue.description, state: issue.status.is_closed ? 'closed' : 'open' )
    end

    def add_comment(journal)
      return if git_issue_number.blank?
      git_comment = api_client.add_comment(repo, git_issue_number, journal.notes)
      journal.build_ventura_comment(git_comment_id: git_comment['id']).save
    end

    def update_comment(journal)
      git_comment_id = journal.git_comment_id
      return if git_comment_id.blank?
      api_client.update_comment(repo, git_comment_id, journal.notes)
    end

    def delete_comment(journal)
      git_comment_id = journal.git_comment_id
      return if git_comment_id.blank?
      api_client.delete_comment(repo, git_comment_id)
    end
  end
end
