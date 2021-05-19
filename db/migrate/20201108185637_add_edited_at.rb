class AddEditedAt < ActiveRecord::Migration
  def change
    add_column :comments, :edited_at, :datetime
  end
end
