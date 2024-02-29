# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_telegrams
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  name           :string
#  status         :integer          default("active"), not null
#  token          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_channel_telegrams_on_account_id                 (account_id)
#  index_channel_telegrams_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_telegrams_on_account_id_and_name        (account_id,name)
#  index_channel_telegrams_on_status                     (status)
#  index_channel_telegrams_on_token                      (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Telegram < ApplicationRecord
    belongs_to :account

    enum status: { active: 0 }
  end
end
