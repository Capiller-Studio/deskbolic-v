# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_sources
#
#  id               :uuid             not null, primary key
#  configurations   :jsonb            not null
#  description      :text
#  headers          :jsonb            not null
#  name             :string           not null
#  params           :jsonb            not null
#  response_mapping :jsonb            not null
#  source_type      :integer          default("api"), not null
#  source_url       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#
# Indexes
#
#  index_identity_sources_on_account_id                 (account_id)
#  index_identity_sources_on_account_id_and_created_at  (account_id,created_at)
#  index_identity_sources_on_account_id_and_name        (account_id,name)
#
class IdentitySource < ShardRecord
  belongs_to :account

  enum source_type: { api: 0 }
end
