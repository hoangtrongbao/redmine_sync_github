module Zg
  module Patches
    module UserPatch
      def self.included(base)
        base.class_eval do
          has_one :ventura_user, dependent: :destroy
        end
      end
    end
  end
end

unless User.included_modules.include?(Zg::Patches::UserPatch)
  User.send(:include, Zg::Patches::UserPatch)
end
