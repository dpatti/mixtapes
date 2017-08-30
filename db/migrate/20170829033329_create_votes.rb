class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer :award_id
      t.integer :user_id
      t.integer :mixtape_id

      t.timestamps
    end
  end
end
