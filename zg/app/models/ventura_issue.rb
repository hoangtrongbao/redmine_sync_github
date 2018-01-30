class VenturaIssue < ActiveRecord::Base
  unloadable
  belongs_to :issue, foreign_key: :issue_id
end
