module Zg
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :ventura_user, dependent: :destroy
        end
      end

      module InstanceMethods
        def authorized_github?
          ventura_user.present?
        end
      end
    end
  end
end

unless User.included_modules.include?(Zg::Patches::UserPatch)
  User.send(:include, Zg::Patches::UserPatch)
end
