class CreateVenturaProjects < ActiveRecord::Migration
  def change
    create_table :ventura_projects do |t|
      t.integer :project_id
      t.string :git_repo_url
    end

    add_index :ventura_projects, :project_id
  end
end
