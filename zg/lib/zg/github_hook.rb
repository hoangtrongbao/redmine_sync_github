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
    # rubocop:disable Metrics/LineLength
    def process
      issue_id = issue_payload['id']
      case @event
      when 'issues'
        issue_sync = Zg::Synchronizer::Github::Issue
        case @payload['action']
        when 'opened'
          issue_sync.create(repository_payload, issue_payload)
        when 'edited'
          issue_sync.new(issue_id, repository_payload).update(@payload['changes'], issue_payload)
        end
      when 'issue_comment'
        comment_sync = Zg::Synchronizer::Github::IssueComment
        comment_id = comment_payload['id']
        case @payload['action']
        when 'created'
          comment_sync.create(issue_id, repository_payload, @payload['comment'])
        when 'edited'
          comment_sync.new(issue_id, repository_payload, comment_id).update(comment_payload)
        when 'deleted'
          comment_sync.new(issue_id, repository_payload, comment_id).destroy
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/LineLength

    def comment_payload
      @payload['comment']
    end

    def repository_payload
      @payload['repository']['full_name']
    end

    def issue_payload
      @payload['issue']
    end
  end
end
