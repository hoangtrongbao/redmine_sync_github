class GitHookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def oauth
    begin
      Zg::GithubAdapter.create_access_token(oauth_params[:username],
                                            oauth_params[:password])
      flash[:notice] = 'Authorized successfully'
    rescue => e
      flash[:error] = e.message
    end

    redirect_to edit_user_path(User.current, tab: 'git_oauth')
  end

  def index
    github_hook = Zg::GithubHook.new(request.env['HTTP_X_GITHUB_EVENT'],
                                     git_payload)
    github_hook.process
    render json: 'success', status: 200
  end

  private

  def oauth_params
    params.require(:zg).permit(:username, :password)
  end

  def git_payload
    JSON.parse(params[:payload] || {})
  end
end
