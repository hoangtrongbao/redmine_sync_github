require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'
require 'zg/synchronizer/github/issue'

module Zg
  module Synchronizer
    module Github
      class IssueComment
        ACTION = {
          CREATE: 'Created',
          EDIT: 'Edited'
        }.freeze

        def initialize(git_issue_id, git_comment)
          @git_issue_id = git_issue_id
          @git_comment = git_comment
        end

        class << self
          def find(id)
            VenturaComment.find_by(git_comment_id: id).try(:journal)
          end

          def exist?(id)
            find(id).present?
          end
        end

        def can_create?
          find_issue.present? && !IssueComment.exist?(id)
        end

        def can_update?
          IssueComment.exist?(id)
        end

        # rubocop:disable Metrics/AbcSize
        def create
          return false unless can_create?
          ::Issue.transaction do
            issue = find_issue
            TimeEntry.new(issue: issue, project: issue.project)
            issue.init_journal(author)
            issue.notes = notes
            issue.save!
            issue.current_journal.build_ventura_comment(git_comment_id: id).save
          end
        end
        # rubocop:enable Metrics/AbcSize

        def id
          @git_comment['id']
        end

        def find_issue
          Issue.find(@git_issue_id)
        end

        def author
          User.find(@git_comment['user']['id'])
        end

        def notes
          @git_comment['body']
        end

        def find_comment
          IssueComment.find(id)
        end

        # rubocop:disable Metrics/LineLength
        def update(git_user)
          content = notes
          content += append_git_user_action(git_user, IssueComment::ACTION[:EDIT]) if author.is_a?(AnonymousUser)
          comment = find_comment
          comment.notes = content
          comment.save!
        end
        # rubocop:enable Metrics/LineLength

        def destroy
          return false unless IssueComment.find(id)
          IssueComment.find(id).destroy
        end

        def append_git_user_action(user, action)
          "\n#{action} by #{user['login']} - #{user['html_url']}"
        end
      end
    end
  end
end
