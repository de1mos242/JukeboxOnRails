class CreateRoomMemberships < ActiveRecord::Migration
  def change
    create_table :room_memberships do |t|
      t.references :user
      t.references :room

      t.timestamps
    end
    add_index :room_memberships, :user_id
    add_index :room_memberships, :room_id
  end
end
