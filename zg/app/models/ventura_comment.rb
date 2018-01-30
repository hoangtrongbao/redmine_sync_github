class VenturaComment < ActiveRecord::Base
  unloadable
  belongs_to :journal, foreign_key: :journal_id

  after_update :update_github_comment
  after_destroy :delete_github_comment

  private

  def delete_github_comment
    repo = journal.issue.project.ventura_project.git_repo_name
    Zg::GithubAdapter.new(repo).delete_comment(git_comment_id)
  end
end
