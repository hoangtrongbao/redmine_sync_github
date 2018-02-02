require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'

module Zg
  module Synchronizer
    module Github
      class Issue
        attr_accessor :git_issue, :project, :user

        ACTION = {
          CREATE: 'Created',
          EDIT: 'Edited',
          CLOSE: 'Closed',
          REOPEN: 'Reopen'
        }.freeze

        STATUS = {
          NEW: 1,
          CLOSE: 5
        }.freeze

        def initialize(git_issue, git_repo, git_user)
          @git_issue = git_issue
          @project = git_repo
          @user = git_user
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
            issue_sync = new(args['id'], Repository.find(repo), args['user'])
            return false unless issue_sync.can_create?
            ::Issue.transaction do
              ::Issue.new.tap do |issue|
                author = issue_sync.find_user
                description = args['body']
                if author.is_a?(AnonymousUser)
                  description += issue_sync.append_git_user_action(args['user'], Issue::ACTION[:CREATE])
                end
                issue.init_journal(author, notes) if notes.present?
                issue.project = issue_sync.project
                issue.author = author
                issue.subject = args['title']
                issue.status_id = 1
                issue.description = description
                issue.tracker = issue.allowed_target_trackers(author).first
                issue.save!
                issue.build_ventura_issue(git_issue_id: args['id'],
                                          git_issue_number: args['number']).save
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        def can_create?
          project.present? && !Issue.exist?(id)
        end

        def can_update?
          project.present? && Issue.exist?(id)
        end

        def assign_label(git_label)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          update_label(priority, tracker)
        end

        def delete_label(git_label)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          # Find priority and tracker after delete
          priority = find_priority(git_issue['labels']) if priority.present?
          tracker = find_tracker(git_issue['labels']) if tracker.present?

          update_label(priority, tracker)
        end

        def update_label(priority, tracker)
          Issue.find(id).tap do |issue|
            issue.init_journal(user)
            issue.priority = priority if priority.present?
            issue.tracker = tracker if tracker.present?
            issue.save!
          end
        end

        def find_tracker(labels)
          labels.reverse.each do |label|
            return get_tracker(label['name']) if get_tracker(label['name']).present?
          end
          Issue.find(id).allowed_target_trackers(user).first
        end

        def find_priority(labels)
          labels.reverse.each do |label|
            return get_priority(label['name']) if get_priority(label['name']).present?
          end
          IssuePriority.find_by(name: 'Normal')
        end

        def get_tracker(label_name)
          Tracker.find_by(name: label_name)
        end

        def get_priority(label_name)
          repo_user = git_repository[:user]
          repo_name = git_repository[:name]
          priority_name = load_label[repo_user][repo_name]['priority'][label_name]
          IssuePriority.find_by(name: priority_name)
        end

        def git_repository
          git_repo = project.split('/')
          { user: git_repo.first.downcase, name: git_repo.last.downcase }
        end

        # rubocop:disable Metrics/LineLength
        def load_label
          YAML.load_file(File.join(Redmine::Plugin.find(:zg).directory, 'config/label.yml'))
        end
        # rubocop:enable Metrics/LineLength

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def update(diffs)
          return false unless can_update?
          diffs_keys = diffs.keys
          Issue.find(git_issue['id']).tap do |issue|
            author = find_user
            if author.is_a?(AnonymousUser)
              author = issue.author
              notes = append_git_user_action(user, Issue::ACTION[:EDIT])
            end
            issue.init_journal(author, (notes || ''))
            issue.subject = issue['title'] if diffs_keys.include?('title')
            issue.description = issue['body'] if diffs_keys.include?('body')
            issue.save!
          end
        end

        def close
          return false unless can_update?
          Issue.find(git_issue['id']).tap do |issue|
            author = find_user
            if author.is_a?(AnonymousUser)
              author = issue.author
              notes = append_git_user_action(user, Issue::ACTION[:CLOSE])
            end
            issue.init_journal(author, (notes || ''))
            issue.status_id = Issue::STATUS[:CLOSE]
            issue.save!
          end
        end

        def reopen
          return false unless can_update?
          Issue.find(id).tap do |issue|
            author = find_user
            if author.is_a?(AnonymousUser)
              author = issue.author
              notes = append_git_user_action(user, Issue::ACTION[:REOPEN])
            end
            issue.init_journal(author, (notes || ''))
            issue.status_id = Issue::STATUS[:NEW]
            issue.save!
          end
        end

        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        def append_git_user_action(user, action)
          "#{action} by #{user['login']} - #{user['html_url']}"
        end

        def find_user
          User.find(user['id'])
        end
      end
    end
  end
end
