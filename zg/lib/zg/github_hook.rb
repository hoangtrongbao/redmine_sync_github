# @TODO: Refactor this class
module Zg
  class GithubHook
    attr_accessor :event, :payload

    def initialize(event, payload)
      @event = event
      @payload = payload
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def process
      project = @payload['repository']['full_name']
      issue_data = @payload['issue']
      case @event
      when 'issues'
        issue_sync = Zg::Synchronizer::Github::Issue
        case @payload['action']
        when 'opened'
          issue_sync.create(project, issue_data)
        when 'edited'
          issue_sync.new(issue_data['id'], project).update(@payload['changes'], issue_data)
        end
      when 'issue_comment'
        comment_sync = Zg::Synchronizer::Github::IssueComment
        case @payload['action']
        when 'created'
          comment_sync.create(issue_data['id'], project, @payload['comment'])
        when 'edited'
          comment_sync.new(issue_data['id'], project, @payload['comment']['id']).update(@payload['comment'])
        when 'deleted'
          comment_sync.new(issue_data['id'], project, @payload['comment']['id']).destroy
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
