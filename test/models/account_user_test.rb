# frozen_string_literal: true

# == Schema Information
#
# Table name: account_users
#
#  id                      :uuid             not null, primary key
#  availability            :integer          default("offline"), not null
#  availability_changed_at :datetime
#  last_activity_at        :datetime
#  role                    :integer          default("agent"), not null
#  status                  :integer          default("active"), not null
#  status_changed_at       :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :uuid             not null
#  invited_by_id           :uuid
#  user_id                 :uuid             not null
#
# Indexes
#
#  index_account_users_on_account_id              (account_id)
#  index_account_users_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_account_users_on_availability            (availability)
#  index_account_users_on_created_at              (created_at)
#  index_account_users_on_invited_by_id           (invited_by_id)
#  index_account_users_on_role                    (role)
#  index_account_users_on_status                  (status)
#  index_account_users_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (invited_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class AccountUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
