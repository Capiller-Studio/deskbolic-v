# frozen_string_literal: true

# == Schema Information
#
# Table name: sla_policies
#
#  id                          :uuid             not null, primary key
#  configurations              :jsonb            not null
#  description                 :text
#  during_working_hours        :boolean          default(FALSE), not null
#  initial_response_time_limit :float
#  name                        :string           not null
#  resolution_time_limit       :float
#  response_time_limit         :float
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :uuid             not null
#
# Indexes
#
#  index_sla_policies_on_account_id                 (account_id)
#  index_sla_policies_on_account_id_and_created_at  (account_id,created_at)
#  index_sla_policies_on_account_id_and_name        (account_id,name)
#
class SlaPolicy < ShardRecord
  belongs_to :account
end
