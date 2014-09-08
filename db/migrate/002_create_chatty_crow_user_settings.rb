class CreateChattyCrowUserSettings < ActiveRecord::Migration
  def change
    create_table :chatty_crow_user_settings, id: false do |t|
      t.references :user, index: true
      t.references :chatty_crow_channel, index: true
      t.string :contact
    end
  end
end
