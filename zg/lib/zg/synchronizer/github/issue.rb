require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'

module Zg
  module Synchronizer
    module Github
      class Issue
        attr_accessor :id, :project

        def initialize(id, project)
          @id = id
          @project = project
        end

        class << self
          def find(id)
            VenturaIssue.find_by(git_issue_id: id).try(:issue)
          end

          def exist?(id)
            find(id).present?
          end

          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/MethodLength
          def create(repo, args)
            issue_sync = new(args['id'], Repository.find(repo))
            return false unless issue_sync.can_create?
            ::Issue.transaction do
              ::Issue.new.tap do |issue|
                author = User.find(args['user']['id'])
                issue.project = issue_sync.project
                issue.author = author
                issue.subject = args['title']
                issue.status_id = 1
                issue.description = args['body']
                issue.tracker = issue.allowed_target_trackers(author).first
                issue.save!
                issue.build_ventura_issue(git_issue_id: args['id'], git_issue_number: args['number']).save
              end
            end
          end
        end

        def assign_label(git_label, args)
          return false unless can_update?

          label_name = git_label['name']
          repo_name = project.split('/').last
          prioriry = map_label[repo_name]['priority'][label_name]
          tracker = Tracker.find_by(name: label_name)

          Issue.find(id).tap do |issue|
            issue.init_journal(User.find(args['user']['id']))
            issue.tracker = tracker if tracker.present?
            issue.priority = IssuePriority.find_by(name: prioriry) if prioriry.present?
            issue.save!
          end
        end

        def map_label
           YAML.load_file(File.join(Redmine::Plugin.find(:zg).directory, 'config/label.yml'))
        end

        def can_create?
          project.present? && !Issue.exist?(id)
        end

        def can_update?
          project.present? && Issue.exist?(id)
        end

        def update(diffs, args)
          return false unless can_update?
          diffs_keys = diffs.keys
          Issue.find(id).tap do |issue|
            issue.init_journal(User.find(args['user']['id']))
            issue.subject = args['title'] if diffs_keys.include?('title')
            issue.description = args['body'] if diffs_keys.include?('body')
            issue.save!
          end
        end
      end
    end
  end
end
