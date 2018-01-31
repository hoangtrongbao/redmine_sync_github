module Zg
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_one :ventura_project, dependent: :destroy
        end
      end

      module InstanceMethods
        def sync_with_github?
          ventura_project.present? && ventura_project.git_repo_name.present?
        end
      end
    end
  end
end

unless Project.included_modules.include?(Zg::Patches::ProjectPatch)
  Project.send(:include, Zg::Patches::ProjectPatch)
end
