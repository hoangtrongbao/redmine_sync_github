module Zg
  module Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          has_one :ventura_project, dependent: :destroy
        end
      end
    end
  end
end

unless Project.included_modules.include?(Zg::Patches::ProjectPatch)
  Project.send(:include, Zg::Patches::ProjectPatch)
end