# frozen_string_literal: true

# == Schema Information
#
# Table name: attachments
#
#  id              :uuid             not null, primary key
#  attachment_type :integer          default("image"), not null
#  extension       :string
#  latitude        :float
#  longitude       :float
#  remote_url      :string
#  resource_type   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  resource_id     :uuid             not null
#
# Indexes
#
#  index_attachments_on_account_id                      (account_id)
#  index_attachments_on_account_id_and_attachment_type  (account_id,attachment_type)
#  index_attachments_on_resource                        (resource_type,resource_id)
#
FactoryBot.define do
  factory :attachment do
    attachment_type { "MyString" }
    remote_url { "MyString" }
    latitude { 1.5 }
    longitude { 1.5 }
    resource { nil }
    account { nil }
    extension { "MyString" }
  end
end
