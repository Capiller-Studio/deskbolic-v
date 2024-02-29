# frozen_string_literal: true

# == Schema Information
#
# Table name: email_templates
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             not null
#
# Indexes
#
#  index_email_templates_on_account_id           (account_id)
#  index_email_templates_on_account_id_and_name  (account_id,name)
#
require "test_helper"

class EmailTemplateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
