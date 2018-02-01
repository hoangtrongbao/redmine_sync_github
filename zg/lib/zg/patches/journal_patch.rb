module Zg
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_one :ventura_comment, dependent: :destroy
        end
      end

      module InstanceMethods
        def git_comment_id
          ventura_comment.try(:git_comment_id)
        end
      end
    end
  end
end

unless Journal.included_modules.include?(Zg::Patches::JournalPatch)
  Journal.send(:include, Zg::Patches::JournalPatch)
end
