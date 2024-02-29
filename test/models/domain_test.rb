# frozen_string_literal: true

# == Schema Information
#
# Table name: domains
#
#  id              :uuid             not null, primary key
#  configurations  :jsonb            not null
#  managed         :boolean          default(FALSE), not null
#  name            :string           default("")
#  require_ssl     :boolean          default(TRUE), not null
#  ssl_added_at    :datetime
#  status          :integer          default("active"), not null
#  system_provided :boolean          default(FALSE), not null
#  value           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
# Indexes
#
#  index_domains_on_account_id                 (account_id)
#  index_domains_on_account_id_and_created_at  (account_id,created_at)
#  index_domains_on_managed                    (managed)
#  index_domains_on_status                     (status)
#  index_domains_on_system_provided            (system_provided)
#  index_domains_on_value                      (value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
require "test_helper"

class DomainTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
