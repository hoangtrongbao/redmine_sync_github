module Zg
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :ventura_comment, dependent: :destroy
          after_update :update_github_comment
        end
      end

      module InstanceMethods
        def update_github_comment
          repo = issue.project.ventura_project.git_repo_name
          github_adapter = Zg::GithubAdapter.new(repo)
          github_adapter.update_comment(ventura_comment.git_comment_id,
                                        notes)
        end
      end
    end
  end
end

unless Journal.included_modules.include?(Zg::Patches::JournalPatch)
  Journal.send(:include, Zg::Patches::JournalPatch)
end
