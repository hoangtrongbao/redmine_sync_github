class GitHookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def oauth
    github_adapter = Zg::GithubAdapter.new

    begin
      github_adapter.create_access_token(oauth_params[:username],
                                         oauth_params[:password])
      flash[:notice] = 'Authorized successfully'
    rescue Octokit::Unauthorized => e
      flash[:error] = e.message
    end

    redirect_to home_path
  end

  def index
    params = git_payload
    case request.env['HTTP_X_GITHUB_EVENT']
    when 'issue'
      if params['action'] == 'opened'
        build_new_issue_from_params
        unless github_user.allowed_to?(:add_issues, @issue.project, :global => true)
          raise ::Unauthorized
        end

        @issue.save!
      end
    when 'issue_comment'
      if params['action'] == 'created'
        update_issue_from_params
        Issue.transaction do
          @issue.save
          VenturaComment.create(journal_id: @issue.last_journal_id,
                                git_comment_id: git_payload['comment']['id'])
        end
      end
      if params['action'] == 'deleted'
        VenturaComment.find_by(git_comment_id: git_payload['comment']['id']).destroy
      end
    end
    render json: 'success', status: 200
  end

  private

  def oauth_params
    params.require(:zg).permit(:username, :password)
  end

  # Fetch data from redmine
  def github_user
    git_user = git_payload['user']
    user_id = git_user['id']
    User.find_by(id: user_id)
  end

  def git_payload
    JSON.parse(params[:payload] || {})
  end

  # Used by #edit and #update to set some common instance variables
  # from the params
  def update_issue_from_params
    @issue = Issue.last
    @time_entry = TimeEntry.new(issue: @issue, project: @issue.project)

    git_user_id = git_payload['comment']['user']['id']
    user = VenturaUser.find_by(git_login_id: git_user_id).try(:user)
    @issue.init_journal(user)

    @issue.notes = git_payload['comment']['body']
    true
  end

  # Used by #new and #create to build a new issue from the params
  def build_new_issue_from_params
    @issue = Issue.new
    @issue.project = Project.first
    @issue.author ||= github_user
    @issue.start_date ||= github_user.today if Setting.default_issue_start_date_to_creation_date?
    @issue.subject = parse_payload['issue']['title']
    @issue.status_id = 1
    @issue.description = parse_payload['issue']['body'] if parse_payload['issue']['body'].present?

    if @issue.project
      @issue.tracker ||= @issue.allowed_target_trackers(User.first).first
      if @issue.tracker.nil?
        if @issue.project.trackers.any?
          # None of the project trackers is allowed to the user
          render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403
        else
          # Project has no trackers
          render_error l(:error_no_tracker_in_project)
        end
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    end
  end
end
