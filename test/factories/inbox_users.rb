# frozen_string_literal: true

# == Schema Information
#
# Table name: inbox_users
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inbox_id   :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_inbox_users_on_created_at            (created_at)
#  index_inbox_users_on_inbox_id              (inbox_id)
#  index_inbox_users_on_inbox_id_and_user_id  (inbox_id,user_id) UNIQUE
#  index_inbox_users_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :inbox_user do
    inbox { nil }
    user { nil }
  end
end
