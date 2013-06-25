class RemoveMixtapePassword < ActiveRecord::Migration
  def up
    remove_column :mixtapes, :password
  end

  def down
    add_column :mixtapes, :password, :string
  end
end
