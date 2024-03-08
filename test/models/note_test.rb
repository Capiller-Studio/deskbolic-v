# frozen_string_literal: true

# == Schema Information
#
# Table name: notes
#
#  id            :uuid             not null, primary key
#  content       :text
#  resource_type :string
#  title         :string
#  visibility    :integer          default("personal"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null
#  resource_id   :uuid
#  user_id       :uuid             not null
#
# Indexes
#
#  index_notes_on_account_id                 (account_id)
#  index_notes_on_account_id_and_created_at  (account_id,created_at)
#  index_notes_on_account_id_and_title       (account_id,title)
#  index_notes_on_resource                   (resource_type,resource_id)
#  index_notes_on_user_id                    (user_id)
#
require "test_helper"

class NoteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
