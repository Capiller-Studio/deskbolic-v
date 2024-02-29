# frozen_string_literal: true

# == Schema Information
#
# Table name: business_hour_groups
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  description    :text
#  name           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_business_hour_groups_on_account_id                 (account_id)
#  index_business_hour_groups_on_account_id_and_created_at  (account_id,created_at)
#  index_business_hour_groups_on_account_id_and_name        (account_id,name)
#
class BusinessHourGroup < ShardRecord
  belongs_to :account
end
