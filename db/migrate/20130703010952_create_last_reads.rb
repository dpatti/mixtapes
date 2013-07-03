class CreateLastReads < ActiveRecord::Migration
  def change
    create_table :last_reads do |t|
      t.integer :user_id
      t.integer :mixtape_id
      t.datetime :time
    end

    add_index :last_reads, [:user_id, :mixtape_id], :unique => true
  end
end
