# frozen_string_literal: true

# == Schema Information
#
# Table name: macros
#
#  id         :uuid             not null, primary key
#  actions    :jsonb            not null
#  events     :jsonb            not null
#  macro_type :integer          default("manual"), not null
#  managed    :boolean          default(FALSE), not null
#  name       :string
#  status     :integer          default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_macros_on_account_id                 (account_id)
#  index_macros_on_account_id_and_created_at  (account_id,created_at)
#  index_macros_on_account_id_and_macro_type  (account_id,macro_type)
#  index_macros_on_account_id_and_managed     (account_id,managed)
#  index_macros_on_account_id_and_name        (account_id,name)
#  index_macros_on_account_id_and_status      (account_id,status)
#  index_macros_on_user_id                    (user_id)
#
class Macro < ShardRecord
  belongs_to :account
  belongs_to :user

  enum status: { active: 0 }
  enum macro_type: { manual: 0, event_based: 1 }
end
