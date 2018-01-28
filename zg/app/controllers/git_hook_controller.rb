class GitHookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def oauth
    client = Octokit::Client.new(login: oauth_params[:username],
                                 password: oauth_params[:password])
    client_user = client.user
    oauth_token = client.create_authorization(:scopes => %w[repo],
                                              :note => 'Ventura Redmine')
    VenturaUser.create(user: User.current,
                       git_login: client_user[:login],
                       git_login_id: client_user[:id],
                       oauth_id: oauth_token[:id],
                       oauth_token: oauth_token[:token])
    flash[:notice] = 'Authorized successfully'
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

      if params['comment'].present?
        update_issue_from_params
        Issue.transaction do
          @issue.save
        end
      end
    end
    render json: 'success', status: 200
  end

  private

  def oauth_params
    params.permit(:username, :password)
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
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)

    @issue.init_journal(User.first)

    @issue.notes = parse_payload['comment']['body']
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
