module Zg
  class GithubHook
    attr_accessor :event, :payload

    def initialize(event, payload)
      @event = event
      @payload = payload
    end

    def process
      case @event
      when 'issues'
        case @payload['action']
        when 'opened'
          create_issue
        end
      when 'issue_comment'
        case @payload['action']
        when 'created'
          create_issue_comment
        when 'deleted'
          delete_issue_comment
        end
      end
    end

    private

    def create_issue
      return unless new_issue_from_payload
      new_issue = new_issue_from_payload
      Issue.transaction do
        new_issue.save!
        new_issue.build_ventura_issue(git_issue_id: @payload['issue']['number']).save
      end
    end

    def create_issue_comment
      return unless create_issue_comment_from_payload
      Issue.transaction do
        issue_comment = create_issue_comment_from_payload.save!
        VenturaComment.create(journal_id: issue_comment.last_journal_id,
                              git_comment_id: @payload['comment']['id'])
      end
    end

    def delete_issue_comment
      VenturaComment.find_by(git_comment_id: @payload['comment']['id']).destroy
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def new_issue_from_payload
      return false if find_project.blank? || issue_exist?
      issue = Issue.new
      issue.project = find_project
      # @TODO: Map user between Github and Redmine
      issue.author = User.current
      issue.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?
      issue.subject = @payload['issue']['title']
      # @TODO: Need mapping for each project
      issue.status_id = 1 # New issue
      issue.description = @payload['issue']['body']

      if issue.project
        issue.tracker ||= issue.allowed_target_trackers(User.first).first
        if issue.tracker.nil?
          if issue.project.trackers.any?
            # None of the project trackers is allowed to the user
            p l(:error_no_tracker_allowed_for_new_issue_in_project)
          else
            # Project has no trackers
            p l(:error_no_tracker_in_project)
          end
          return false
        end
      end

      issue
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def create_issue_comment_from_payload
      return false if find_issue.blank? || issue_comment_exist?
      issue = find_issue
      TimeEntry.new(issue: issue, project: issue.project)

      git_user_id = @payload['comment']['user']['id']
      user = VenturaUser.find_by(git_login_id: git_user_id).try(:user)
      issue.init_journal(user)
      issue.notes = @payload['comment']['body']
      issue
    end

    def find_project
      git_project = VenturaProject.find_by(git_repo_name: @payload['repository']['full_name'])
      git_project.present? ? git_project.project : false
    end

    def find_issue
      git_issue = VenturaIssue.find_by(git_issue_id: @payload['issue']['id'])
      git_issue.present? ? git_issue.issue : false
    end

    # @TODO: Map Github user with Redmine
    def find_user; end

    def issue_exist?
      git_issue_id = @payload['issue']['id']
      VenturaIssue.find_by(git_issue_id: git_issue_id).present?
    end

    def issue_comment_exist?
      git_comment_id = @payload['comment']['id']
      VenturaComment.find_by(git_comment_id: git_comment_id).present?
    end
  end
end
