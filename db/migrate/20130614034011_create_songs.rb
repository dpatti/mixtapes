class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :name
      t.string :artist
      t.string :album
      t.integer :track_number
      t.integer :duration
      t.string :file
      t.binary :cover_art

      t.timestamps
    end
  end
end
