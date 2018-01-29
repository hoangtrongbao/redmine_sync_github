module Zg
  module Patches
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          before_action :validate_github_authorized
          after_action :build_git_repo_url, only: %i[create update]
        end
      end

      module InstanceMethods
        def validate_github_authorized
          return if User.current.blank?
          return if User.current.authorized_github?
          flash[:error] = 'Please authorize your account with Github'
          redirect_to home_path
        end

        def build_git_repo_url
          git_repo_url = params[:project][:git_repo_url]
          git_repo_name = git_repo_url.sub('https://github.com/', '') if git_repo_url.present?
          return if @project.errors.any? || git_repo_url.blank?
          # @TODO: Check if ventura project exist?
          VenturaProject.create(project: @project,
                                git_repo_url: git_repo_url,
                                git_repo_name: git_repo_name)
        end
      end
    end
  end
end

unless ProjectsController.included_modules.include?(Zg::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, Zg::Patches::ProjectsControllerPatch)
end
