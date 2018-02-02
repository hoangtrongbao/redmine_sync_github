require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'

module Zg
  module Synchronizer
    module Github
      class Issue
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
          @git_repo = git_repo
          @git_user = git_user
        end

        class << self
          def find(id)
            VenturaIssue.find_by(git_issue_id: id).try(:issue)
          end

          def exist?(id)
            find(id).present?
          end
        end

        def can_create?
          project.present? && !Issue.exist?(@git_issue['id'])
        end

        def can_update?
          project.present? && Issue.exist?(@git_issue['id'])
        end

        def update(diffs)
          return false unless can_update?
          Issue.find(@git_issue['id']).tap do |issue|
            issue.init_journal(author, notes(Issue::ACTION[:EDIT]))
            issue.safe_attributes = update_params(diffs.keys), author
            issue.save!
          end
        end

        def close
          return false unless can_update?
          Issue.find(@git_issue['id']).tap do |issue|
            issue.init_journal(author, notes(Issue::ACTION[:CLOSE]))
            issue.status_id = Issue::STATUS[:CLOSE]
            issue.save!
          end
        end

        def reopen
          return false unless can_update?
          Issue.find(@git_issue['id']).tap do |issue|
            issue.init_journal(author, notes(Issue::ACTION[:REOPEN]))
            issue.status_id = Issue::STATUS[:NEW]
            issue.save!
          end
        end

        def assign_label(git_label)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          update_label(priority, tracker)
        end

        def update_label(priority, tracker)
          Issue.find(@git_issue['id']).tap do |issue|
            issue.init_journal(author)
            issue.priority = priority if priority.present?
            issue.tracker = tracker if tracker.present?
            issue.save!
          end
        end

        def delete_label(git_label)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          # Find priority and tracker after delete
          priority = find_priority(@git_issue['labels']) if priority.present?
          tracker = find_tracker(@git_issue['labels']) if tracker.present?

          update_label(priority, tracker)
        end

        def find_tracker(labels)
          labels.reverse.each do |label|
            return get_tracker(label['name']) if get_tracker(label['name']).present?
          end
          Issue.find(@git_issue['id']).allowed_target_trackers(user).first
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

        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        def append_git_user_action(user, action)
          "\n#{action} by #{user['login']} - #{user['html_url']}"
        end

        def find_user
          User.find(user['id'])
        end

        def id
          @git_issue['id']
        end

        def number
          @git_issue['number']
        end

        def subject
          @git_issue['title']
        end

        def description
          desc = @git_issue['body']
          desc += append_git_user_action(args['user'], Issue::ACTION[:CREATE]) if author.is_a?(AnonymousUser)
          desc
        end

        def author
          User.find(@git_user['id'])
        end

        def tracker
          return nil if Issue.find(@git_issue['id']).blank?
          Issue.find(@git_issue['id']).allowed_target_trackers(author).first
        end

        def project
          Repository.find(@git_repo)
        end

        def notes(type = nil)
          return '' unless author.is_a?(AnonymousUser)
          append_git_user_action(author, type)
        end

        def create
          return false unless can_create?
          ::Issue.transaction do
            ::Issue.new.tap do |issue|
              issue.safe_attributes = create_params, author
              issue.save!
              issue.build_ventura_issue(git_issue_id: id,
                                        git_issue_number: number).save
            end
          end
        end

        private

        def create_params
          params = {}
          params[:subject] = subject
          params[:description] = description
          params[:project] = project
          params[:tracker] = tracker
          params[:status_id] = Issue::STATUS[:NEW]
          params
        end

        def update_params(diffs_keys)
          params = {}
          params[:subject] = subject if diffs_keys.include?('title')
          params[:description] = description if diffs_keys.include?('body')
          params
        end

        def git_repository
          git_repo = @git_repo.split('/')
          { user: git_repo.first.downcase, name: git_repo.last.downcase }
        end

        # rubocop:disable Metrics/LineLength
        def load_label
          YAML.load_file(File.join(Redmine::Plugin.find(:zg).directory, 'config/label.yml'))
        end
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end
