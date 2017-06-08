class CreatePasswordResetTokens < ActiveRecord::Migration
  def change
    create_table :password_reset_tokens do |t|
      t.references :user, index: true
      t.string :token
      t.datetime :expires_at
      t.timestamps null: false
    end
  end
end
