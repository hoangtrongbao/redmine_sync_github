module Zg
  module Synchronizer
    module Github
      class User
        class << self
          def find(id)
            VenturaUser.find_by(git_login_id: id).try(:user)
          end
        end
      end
    end
  end
end
