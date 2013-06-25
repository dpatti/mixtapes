class AddSongMixtapeId < ActiveRecord::Migration
  def change
    add_column :songs, :mixtape_id, :integer
  end
end
