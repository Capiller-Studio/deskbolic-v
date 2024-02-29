# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_twitter_profiles
#
#  id                 :uuid             not null, primary key
#  handle_tweets      :boolean          default(TRUE), not null
#  name               :string
#  profile_identifier :string           not null
#  status             :integer          default("active"), not null
#  tokens             :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :uuid             not null
#
# Indexes
#
#  idx_on_account_id_profile_identifier_4a1bc813e6              (account_id,profile_identifier) UNIQUE
#  index_channel_twitter_profiles_on_account_id                 (account_id)
#  index_channel_twitter_profiles_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_twitter_profiles_on_account_id_and_name        (account_id,name)
#  index_channel_twitter_profiles_on_profile_identifier         (profile_identifier)
#  index_channel_twitter_profiles_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class TwitterProfile < ApplicationRecord
    belongs_to :account

    enum status: { active: 0 }
  end
end
