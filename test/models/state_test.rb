# frozen_string_literal: true

# == Schema Information
#
# Table name: states
#
#  id         :uuid             not null, primary key
#  abbr       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  country_id :uuid             not null
#
# Indexes
#
#  index_states_on_abbr        (abbr)
#  index_states_on_country_id  (country_id)
#  index_states_on_created_at  (created_at)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id) ON DELETE => cascade
#
require "test_helper"

class StateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
