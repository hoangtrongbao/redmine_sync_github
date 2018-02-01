module Zg
  module Synchronizer
    module Github
      class User
        class << self
          # rubocop:disable Metrics/LineLength
          def find(id, login = nil)
            VenturaUser.find_by(git_login_id: id).try(:user) || ::User.find_by_login(login) || AnonymousUser.first
          end
          # rubocop:enable Metrics/LineLength
        end
      end
    end
  end
end
