# frozen_string_literal: true

module Utilities
  module AttachmentTypeHelpers
    # TODO: Adding missing formats, them remove wildcard

    IMAGE_MIME_TYPES = [
      "image/png",
      "image/jpg",
      "image/jpeg",
      "image/gif",
      "image/webp",
      "image/bmp",
      "image"
    ].freeze
    VIDEO_MIME_TYPES = [
      "video/webm",
      "video/mp4",
      "video/quicktime",
      "video"
    ].freeze
    AUDIO_MIME_TYPES = [
      "audio"
    ].freeze

    def self.attachment_type(type)
      return :image if image?(type)
      return :video if video?(type)
      return :audio if audio?(type)

      :file
    end

    def self.image?(type)
      IMAGE_MIME_TYPES.include?(type)
    end

    def self.video?(type)
      VIDEO_MIME_TYPES.include?(type)
    end

    def self.audio?(type)
      AUDIO_MIME_TYPES.include?(type)
    end
  end
end
