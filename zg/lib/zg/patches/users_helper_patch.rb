module Zg
  module Patches
    module UsersHelperPatch
      def self.prepended(base)
        base.send(:prepend, InstanceMethods)
      end

      module InstanceMethods
        def user_settings_tabs
          tabs = super
          tabs << { name: 'git_oauth',
                    partial: 'users/oauth',
                    label: :git_oauth }
          tabs
        end
      end
    end
  end
end

unless UsersHelper.included_modules.include?(Zg::Patches::UsersHelperPatch)
  UsersHelper.send(:prepend, Zg::Patches::UsersHelperPatch)
end
