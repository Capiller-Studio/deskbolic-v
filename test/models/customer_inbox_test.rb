# frozen_string_literal: true

# == Schema Information
#
# Table name: customer_inboxes
#
#  id          :uuid             not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  customer_id :uuid             not null
#  inbox_id    :uuid             not null
#
# Indexes
#
#  index_customer_inboxes_on_customer_id               (customer_id)
#  index_customer_inboxes_on_customer_id_and_inbox_id  (customer_id,inbox_id) UNIQUE
#  index_customer_inboxes_on_inbox_id                  (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
require "test_helper"

class CustomerInboxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
