class VenturaProject < ActiveRecord::Base
  unloadable
  belongs_to :project, foreign_key: :project_id
end
