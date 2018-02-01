# @TODO: Refactor this class
module Zg
  class GithubHook
    attr_accessor :event, :payload, :action

    def initialize(event, payload)
      @event = event
      @payload = payload
      @action = payload['action']
    end

    def process
      case event
      when 'issues'
        process_issue
      when 'issue_comment'
        process_issue_comment
      end
    end

    def comment_payload
      @payload['comment']
    end

    def repository_payload
      @payload['repository']['full_name']
    end

    def issue_payload
      @payload['issue']
    end

    private

    def process_issue
      issue_sync = Zg::Synchronizer::Github::Issue
      issue_id = issue_payload['id']
      case action
      when 'opened'
        issue_sync.create(repository_payload, issue_payload)
      when 'edited'
        issue_sync.new(issue_id, repository_payload).update(@payload['changes'],
                                                            @payload['sender'],
                                                            issue_payload)
      when 'labeled'
        issue_sync.new(issue_id, repository_payload).assign_label(@payload['label'], issue_payload)
      when 'unlabeled'

      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def process_issue_comment
      comment_sync = Zg::Synchronizer::Github::IssueComment
      comment_id = comment_payload['id']
      issue_id = issue_payload['id']
      case action
      when 'created'
        comment_sync.create(issue_id, repository_payload, comment_payload)
      when 'edited'
        comment_sync.new(issue_id, repository_payload, comment_id).update(comment_payload)
      when 'deleted'
        comment_sync.new(issue_id, repository_payload, comment_id).destroy
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
end
