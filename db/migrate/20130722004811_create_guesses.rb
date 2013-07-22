class CreateGuesses < ActiveRecord::Migration
  def change
    create_table :guesses do |t|
      t.integer :user_id
      t.integer :mixtape_id
      t.integer :user_guessed_id

      t.timestamps
    end
  end
end
