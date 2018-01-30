class VenturaUser < ActiveRecord::Base
  unloadable
  belongs_to :user, foreign_key: :user_id
end
