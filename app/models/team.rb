# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id          :uuid             not null, primary key
#  auto_assign :boolean          default(TRUE), not null
#  description :text
#  flags       :integer          default(0), not null
#  identifier  :string           not null
#  name        :string           not null
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#
# Indexes
#
#  index_teams_on_account_id                 (account_id)
#  index_teams_on_account_id_and_created_at  (account_id,created_at)
#  index_teams_on_account_id_and_flags       (account_id,flags)
#  index_teams_on_account_id_and_identifier  (account_id,identifier) UNIQUE
#  index_teams_on_account_id_and_name        (account_id,name)
#  index_teams_on_account_id_and_status      (account_id,status)
#
class Team < ShardRecord
  belongs_to :account

  enum status: { active: 0 }
end
