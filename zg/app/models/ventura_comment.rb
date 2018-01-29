class VenturaComment < ActiveRecord::Base
  belongs_to :journal, foreign_key: :journal_id
  after_destroy :sync_github_comment

  private

  def sync_github_comment
    user = User.current
    oauth_token = user.ventura_user.oauth_token
    client = Octokit::Client.new(access_token: oauth_token)
    client.delete_comment('phucdh/test_redmine', git_comment_id)
  end
end
