class CreateChattyCrowChannels < ActiveRecord::Migration
  def change
    create_table :chatty_crow_channels do |t|
      t.string :channel_type
      t.string :channel_token
      t.boolean :active, default: true
    end
  end
end
