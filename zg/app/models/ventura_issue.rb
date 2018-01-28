class VenturaIssue < ActiveRecord::Base
  belongs_to :issue, foreign_key: :issue_id
end
