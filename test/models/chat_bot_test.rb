# frozen_string_literal: true

# == Schema Information
#
# Table name: chat_bots
#
#  id             :uuid             not null, primary key
#  api_url        :string
#  bot_type       :integer          default("api"), not null
#  configurations :jsonb            not null
#  description    :text
#  display_name   :string
#  flags          :integer          default(0), not null
#  identifier     :string           not null
#  name           :string
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_chat_bots_on_account_id                 (account_id)
#  index_chat_bots_on_account_id_and_bot_type    (account_id,bot_type)
#  index_chat_bots_on_account_id_and_created_at  (account_id,created_at)
#  index_chat_bots_on_account_id_and_flags       (account_id,flags)
#  index_chat_bots_on_account_id_and_identifier  (account_id,identifier) UNIQUE
#  index_chat_bots_on_account_id_and_name        (account_id,name)
#  index_chat_bots_on_account_id_and_status      (account_id,status)
#
require "test_helper"

class ChatBotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
