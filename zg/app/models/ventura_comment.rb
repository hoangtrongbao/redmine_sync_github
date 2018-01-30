class VenturaComment < ActiveRecord::Base
  unloadable
  belongs_to :journal, foreign_key: :journal_id
end
