# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  email_flags    :integer          default(0), not null
#  push_flags     :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  index_notification_settings_on_account_id              (account_id)
#  index_notification_settings_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_notification_settings_on_user_id                 (user_id)
#  index_notification_settings_on_user_id_and_created_at  (user_id,created_at)
#
class NotificationSetting < ShardRecord
  belongs_to :account
  belongs_to :user
end
