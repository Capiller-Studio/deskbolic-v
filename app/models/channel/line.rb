# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_lines
#
#  id              :uuid             not null, primary key
#  configurations  :jsonb            not null
#  line_identifier :string           not null
#  name            :string
#  secret          :string           not null
#  status          :integer          default("active"), not null
#  token           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
# Indexes
#
#  index_channel_lines_on_account_id                 (account_id)
#  index_channel_lines_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_lines_on_account_id_and_name        (account_id,name)
#  index_channel_lines_on_line_identifier            (line_identifier) UNIQUE
#  index_channel_lines_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Line < ApplicationRecord
    belongs_to :account

    enum status: { active: 0 }
  end
end
