module Zg
  class GithubHook
    attr_accessor :payload

    def initialize(payload)
      @payload = payload
    end

    def process

    end

    def process_issue
      if @payload['action'] == 'opened'

      end
    end

    private

    def build_new_issue_from_payload
      issue = Issue.new
      issue.project = Project.first
      issue.author ||= github_user
      issue.start_date ||= github_user.today if Setting.default_issue_start_date_to_creation_date?
      issue.subject = @payload['issue']['title']
      # New issue
      issue.status_id = 1
      issue.description = @payload['issue']['body'] if @payload['issue']['body'].present?

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

    def update_issue_from_payload

    end
  end
end
