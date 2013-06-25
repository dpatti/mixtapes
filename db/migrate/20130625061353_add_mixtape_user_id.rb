class AddMixtapeUserId < ActiveRecord::Migration
  def change
    add_column :mixtapes, :user_id, :integer
  end
end
