# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_apis
#
#  id                     :uuid             not null, primary key
#  configurations         :jsonb            not null
#  data                   :jsonb            not null
#  name                   :string
#  status                 :integer          default("active"), not null
#  webhook_configurations :jsonb            not null
#  webhook_password       :string
#  webhook_secret         :string           not null
#  webhook_url            :string
#  webhook_username       :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#
# Indexes
#
#  index_channel_apis_on_account_id                 (account_id)
#  index_channel_apis_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_apis_on_account_id_and_name        (account_id,name)
#  index_channel_apis_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Api < ApplicationRecord
    belongs_to :account

    enum status: { active: 0 }
  end
end
