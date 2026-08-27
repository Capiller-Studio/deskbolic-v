# frozen_string_literal: true

module Dashboard
  module AvatarHelper
    def avatar_fallback_color_class(name)
      seed = name.to_s.strip.downcase
      index = seed.present? ? seed.each_byte.sum % 8 : 0

      "avatar-fallback-#{index + 1}"
    end

    def full_name(resource)
      return nil unless resource

      [ resource.try(:first_name), resource.try(:middle_name), resource.try(:last_name) ].compact_blank.join(" ").presence ||
        resource.try(:name).presence || resource.try(:display_name).presence
    end

    def initials(resource, limit: 1)
      return "?" if full_name(resource).blank?

      words = full_name(resource).split
      return words.first.first(limit).upcase if words.one?

      words.first(limit).filter_map(&:first).join.upcase
    end
  end
end
