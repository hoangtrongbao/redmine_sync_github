module Zg
  class GithubHook
    attr_accessor :event, :payload

    def initialize(event, payload)
      @event = event
      @payload = payload
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def process
      case @event
      when 'issues'
        case @payload['action']
        when 'opened'
          create_issue
        when 'edited'
          edit_issue
        end
      when 'issue_comment'
        case @payload['action']
        when 'created'
          create_issue_comment
        when 'edited'
          update_issue_comment
        when 'deleted'
          delete_issue_comment
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    def create_issue
      return unless new_issue_from_payload
      new_issue = new_issue_from_payload
      Issue.transaction do
        new_issue.save!
        new_issue.build_ventura_issue(git_issue_id: @payload['issue']['number']).save
      end
    end

    # rubocop:disable Metrics/LineLength
    def edit_issue
      return false unless find_project && find_issue
      key_changes = @payload['changes'].keys
      issue = find_issue
      issue.subject = @payload['issue']['title'] if key_changes.include?('title')
      issue.description = @payload['issue']['body'] if key_changes.include?('body')
      issue.save!
    end
    # rubocop:enable Metrics/LineLength

    # rubocop:disable Metrics/LineLength
    def create_issue_comment
      return unless create_issue_comment_from_payload
      issue_comment = create_issue_comment_from_payload
      Issue.transaction do
        issue_comment.save!
        issue_comment.current_journal.build_ventura_comment(git_comment_id: @payload['comment']['id']).save
      end
    end
    # rubocop:enable Metrics/LineLength

    def update_issue_comment
      return unless find_issue && find_issue_comment
      git_comment = VenturaComment.find_by(git_comment_id: @payload['comment']['id'])
      return unless git_comment
      git_comment.journal.update(notes: @payload['comment']['body'])
    end

    def delete_issue_comment
      VenturaComment.find_by(git_comment_id: @payload['comment']['id']).destroy if issue_comment_exist?
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def new_issue_from_payload
      return false if !find_project || find_issue
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
      return false if !find_issue || find_issue_comment
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
      git_project.try(:project)
    end

    def find_issue
      git_issue = VenturaIssue.find_by(git_issue_id: @payload['issue']['number'])
      git_issue.try(:issue)
    end

    # @TODO: Map Github user with Redmine
    def find_user; end

    def find_issue_comment
      git_comment = @payload['comment']['id']
      VenturaComment.find_by(git_comment_id: git_comment)
    end
  end
end
