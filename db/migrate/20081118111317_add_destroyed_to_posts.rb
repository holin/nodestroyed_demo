class AddDestroyedToPosts < ActiveRecord::Migration
  def self.up
    add_column :posts, :destroyed, :boolean, :default => false
    add_index :posts, [:destroyed]
  end

  def self.down
    remove_column :posts, :destroyed
    remove_index :posts, [:destroyed]
  end
end
