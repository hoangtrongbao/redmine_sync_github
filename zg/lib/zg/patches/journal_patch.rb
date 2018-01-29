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
          user = User.current
          oauth_token = user.ventura_user.oauth_token
          client = Octokit::Client.new(access_token: oauth_token)
          client.update_comment('phucdh/test_redmine',
                                ventura_comment.git_comment_id,
                                notes)
        end
      end
    end
  end
end

unless Journal.included_modules.include?(Zg::Patches::JournalPatch)
  Journal.send(:include, Zg::Patches::JournalPatch)
end
