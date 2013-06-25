class RenameSongNameToTitle < ActiveRecord::Migration
  def up
    rename_column :songs, :name, :title
  end

  def down
    rename_column :songs, :title, :name
  end
end
