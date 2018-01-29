class CreateVenturaProjects < ActiveRecord::Migration
  def change
    create_table :ventura_projects do |t|
      t.integer :project_id
      t.string :git_repo_url
      t.string :git_repo_name
    end

    add_index :ventura_projects, :project_id
  end
end
