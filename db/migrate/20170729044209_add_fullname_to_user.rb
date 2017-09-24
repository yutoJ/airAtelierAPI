class AddFullnameToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :fullname, :string, default: "", null: false
  end
end
