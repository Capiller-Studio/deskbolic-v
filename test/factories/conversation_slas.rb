# frozen_string_literal: true

# == Schema Information
#
# Table name: conversation_slas
#
#  id              :uuid             not null, primary key
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  conversation_id :uuid             not null
#  sla_policy_id   :uuid             not null
#
# Indexes
#
#  index_conversation_slas_on_account_id                         (account_id)
#  index_conversation_slas_on_account_id_and_created_at          (account_id,created_at)
#  index_conversation_slas_on_account_id_and_status              (account_id,status)
#  index_conversation_slas_on_conversation_id                    (conversation_id)
#  index_conversation_slas_on_conversation_id_and_sla_policy_id  (conversation_id,sla_policy_id) UNIQUE
#  index_conversation_slas_on_sla_policy_id                      (sla_policy_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (sla_policy_id => sla_policies.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :conversation_sla do
    account { nil }
    sla_policy { nil }
    conversation { nil }
    status { 1 }
  end
end
