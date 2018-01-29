module Zg
  class GithubAdapter
    ACCESS_TOKEN_NAME = 'Ventura Redmine'.freeze

    def initialize
      @api_client = Octokit::Client
      exit if User.current.blank?
    end

    def create_access_token(username, password)
      client = @api_client.new(login: username, password: password)
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
  end
end
