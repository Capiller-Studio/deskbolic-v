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
class Attachment < ShardRecord
  belongs_to :resource, polymorphic: true
  belongs_to :account

  has_one_attached :file

  #  TODO: File validations

  enum attachment_type: { image: 0, file: 1, video: 2, audio: 3, location: 4 }

  def direct_download_url
    return unless file.attached?

    if ActiveStorage::Current.url_options.blank?
      ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
    end
    file.blob.url
  end
end
