module Zg
  module Patches
    module ProjectsPatch
      def self.included(base)
        base.class_eval do
          has_one :ventura_project, dependent: :destroy
        end
      end
    end
  end
end

unless Project.included_modules.include?(Zg::Patches::ProjectsPatch)
  Project.send(:include, Zg::Patches::ProjectsPatch)
end
