class CreateVenturaIssues < ActiveRecord::Migration
  def change
    create_table :ventura_issues do |t|
      t.integer :issue_id
      t.integer :git_issue_id
      t.integer :git_issue_number
    end

    add_index :ventura_issues, :issue_id
    add_index :ventura_issues, :git_issue_id
    add_index :ventura_issues, :git_issue_number
  end
end
