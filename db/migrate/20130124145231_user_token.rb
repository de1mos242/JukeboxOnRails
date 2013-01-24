class UserToken < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      ## Database authenticatable
      t.string :token, :null => false, :default => "empty"
    end
  end
end
