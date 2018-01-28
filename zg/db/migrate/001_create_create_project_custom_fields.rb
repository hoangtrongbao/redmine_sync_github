class CreateCreateProjectCustomFields < ActiveRecord::Migration
  def change
    ProjectCustomField.create(name: 'Repository URL',
                              field_format: 'string')
  end
end
