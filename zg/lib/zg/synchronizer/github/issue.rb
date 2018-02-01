require 'zg/synchronizer/github/repository'
require 'zg/synchronizer/github/user'

module Zg
  module Synchronizer
    module Github
      class Issue
        delegate :url_helpers, to: 'Rails.application.routes'
        include ActionView::Helpers::UrlHelper

        attr_accessor :id, :project, :user

        def initialize(id, project, user)
          @id = id
          @project = project
          @user = User.find(user['id'])
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
                issue.build_ventura_issue(git_issue_id: args['id'],
                                          git_issue_number: args['number']).save
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        def assign_label(git_label, args)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          update_label(priority, tracker)
        end

        def delete_label(git_label, args)
          return false unless can_update?
          # Mapping tracker and priority
          priority = get_priority(git_label['name'])
          tracker = get_tracker(git_label['name'])

          # Find priority and tracker after delete
          priority = find_priority(args['labels']) if priority.present?
          tracker = find_tracker(args['labels']) if tracker.present?

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

        def can_create?
          project.present? && !Issue.exist?(id)
        end

        def can_update?
          project.present? && Issue.exist?(id)
        end

        # rubocop:disable Metrics/LineLength
        # rubocop:disable Metrics/AbcSize
        def update(diffs, edit_user, args)
          return false unless can_update?
          diffs_keys = diffs.keys
          Issue.find(id).tap do |issue|
            author = User.find(edit_user['id'])
            notes = ''
            if author.blank?
              author = issue.author
              notes = "Edited by #{link_to(edit_user['login'], edit_user['html_url'])}"
            end
            issue.init_journal(author, notes)
            issue.subject = args['title'] if diffs_keys.include?('title')
            issue.description = args['body'] if diffs_keys.include?('body')
            issue.save!
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end
