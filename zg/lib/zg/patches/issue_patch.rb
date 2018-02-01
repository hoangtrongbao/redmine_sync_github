module Zg
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_one :ventura_issue, dependent: :destroy
        end
      end

      module InstanceMethods
        def git_issue_number
          ventura_issue.try(:git_issue_number)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(Zg::Patches::IssuePatch)
  Issue.send(:include, Zg::Patches::IssuePatch)
end
