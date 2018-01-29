module Zg
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :ventura_comment, dependent: :destroy
        end
      end

      module InstanceMethods

      end
    end
  end
end

unless Journal.included_modules.include?(Zg::Patches::JournalPatch)
  Journal.send(:include, Zg::Patches::JournalPatch)
end