class CreateChannelTwilioSms < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_twilio_sms, id: :uuid do |t|
      # t.string :phone_code
      # t.string :phone_number
      # t.string :token
      # t.string :api_key
      # t.integer :medium
      # t.references :account, null: false, foreign_key: true, type: :uuid

      # t.timestamps

      # TODO: Remove, Channel::ShortMessage would be used instead. Maybe we need to remove all specific Channel models and use a generic Channel model where we can use a single service enum and jsonb  for storing specific details. 
    end
  end
end
