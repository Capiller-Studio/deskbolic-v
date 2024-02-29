# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
#  id              :uuid             not null, primary key
#  iso             :string           not null
#  iso3            :string           not null
#  iso_name        :string           not null
#  numeric_code    :integer
#  states_required :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_countries_on_created_at      (created_at)
#  index_countries_on_iso             (iso) UNIQUE
#  index_countries_on_iso3            (iso3) UNIQUE
#  index_countries_on_lower_iso_name  (lower((iso_name)::text)) UNIQUE
#
FactoryBot.define do
  factory :country do
    iso { "" }
  end
end
