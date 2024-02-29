# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: business_hours
#
#  id                     :uuid             not null, primary key
#  close_from             :datetime
#  close_till             :datetime
#  closing_time           :time
#  configurations         :jsonb            not null
#  day_of_week            :integer
#  opening_time           :time
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  business_hour_group_id :uuid             not null
#
# Indexes
#
#  index_business_hours_on_account_id                             (account_id)
#  index_business_hours_on_business_hour_group_id                 (business_hour_group_id)
#  index_business_hours_on_business_hour_group_id_and_created_at  (business_hour_group_id,created_at)
#  index_business_hours_on_close_time                             (business_hour_group_id,close_from,close_till)
#  index_business_hours_on_work_time                              (business_hour_group_id,day_of_week,opening_time,closing_time)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => cascade
#
# rubocop:enable Metrics/LineLength
class BusinessHour < ShardRecord
  belongs_to :account
end
