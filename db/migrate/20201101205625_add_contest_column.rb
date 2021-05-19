class AddContestColumn < ActiveRecord::Migration
  def change
    add_column :mixtapes, :contest_id, :integer
  end
end
