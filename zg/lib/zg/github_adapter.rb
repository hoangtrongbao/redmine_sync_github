module Zg
  class GithubAdapter
    ACCESS_TOKEN_NAME = 'Ventura Redmine'.freeze

    def initialize(repo = nil)
      @api_client = Octokit::Client.new(access_token: User.current.ventura_user.oauth_token)
      @repo = repo
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

    def create_issue(title, description)
      @api_client.create_issue(@repo, title, description)
    end

    def update_issue(issue_id, title, body, options = {})
      @api_client.update_issue(@repo, issue_id, title, body, options)
    end

    def add_comment(issue_id, content)
      @api_client.add_comment(@repo, issue_id, content)
    end

    def update_comment(comment_id, content)
      @api_client.update_comment(@repo, comment_id, content)
    end

    def delete_comment(comment_id)
      @api_client.delete_comment(@repo, comment_id)
    end
  end
end
