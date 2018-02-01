require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'
require 'zg/synchronizer/github/issue'

module Zg
  module Synchronizer
    module Github
      class IssueComment
        attr_accessor :issue, :project, :id

        def initialize(issue, project, id)
          @issue = issue
          @project = project
          @id = id
        end

        class << self
          def find(id)
            VenturaComment.find_by(git_comment_id: id).try(:journal)
          end

          def exist?(id)
            find(id).present?
          end

          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/MethodLength
          def create(issue_id, repo, args)
            issue = Issue.find(issue_id)
            project = Repository.find(repo)
            comment = new(issue, project, args['id'])
            return false unless comment.can_create?
            ::Issue.transaction do
              ::TimeEntry.new(issue: issue, project: issue.project)
              author = User.find(args['user']['id'])
              notes = args['body']
              if author.blank?
                author = AnonymousUser.first
                notes = args['body'] + "\nCreated by #{link_to(args['user']['login'], args['user']['html_url'])}"
              end
              issue.init_journal(author)
              issue.notes = notes
              issue.save!
              issue.current_journal.build_ventura_comment(git_comment_id: args['id']).save
            end
          end
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/MethodLength
        end

        def can_create?
          issue.present? && !IssueComment.exist?(id)
        end

        def can_update?
          IssueComment.exist?(id)
        end

        # rubocop:disable Metrics/AbcSize
        def update(args, user)
          IssueComment.find(id).tap do |comment|
            notes = args['body']
            if User.find(user['id']).blank?
              notes = args['body'] + "\nUpdated by #{link_to(args['user']['login'], args['user']['html_url'])}"
            end
            comment.notes = notes
            comment.save!
          end
        end
        # rubocop:enable Metrics/AbcSize

        def destroy
          return false unless IssueComment.find(id)
          IssueComment.find(id).destroy
        end
      end
    end
  end
end
