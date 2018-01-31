module Zg
  module Synchronizer
    module Github
      class Repository
        class << self
          def find(name)
            VenturaProject.find_by(git_repo_name: name).try(:project)
          end
        end
      end
    end
  end
end
