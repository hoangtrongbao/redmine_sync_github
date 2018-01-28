class CreateVenturaComments < ActiveRecord::Migration
  def change
    create_table :ventura_comments do |t|
      t.integer :journal_id
      t.integer :git_comment_id
    end

    add_index :ventura_comments, :journal_id
    add_index :ventura_comments, :git_comment_id
  end
end
