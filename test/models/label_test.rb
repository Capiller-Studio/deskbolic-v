# frozen_string_literal: true

# == Schema Information
#
# Table name: labels
#
#  id             :uuid             not null, primary key
#  color          :string
#  configurations :jsonb            not null
#  description    :text
#  flags          :integer          default(0), not null
#  identifier     :string           not null
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_labels_on_account_id                 (account_id)
#  index_labels_on_account_id_and_created_at  (account_id,created_at)
#  index_labels_on_account_id_and_identifier  (account_id,identifier) UNIQUE
#  index_labels_on_account_id_and_title       (account_id,title)
#
require "test_helper"

class LabelTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
