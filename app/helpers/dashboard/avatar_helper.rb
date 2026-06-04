# frozen_string_literal: true

module Dashboard
  module AvatarHelper
    def avatar_fallback_color_class(name)
      seed = name.to_s.strip.downcase
      index = seed.present? ? seed.each_byte.sum % 8 : 0

      "avatar-fallback-#{index + 1}"
    end

    def full_name(resource)
      [resource.first_name, resource.middle_name, resource.last_name].compact_blank.join(" ").presence || 
        resource.name.presence || resource.display_name.presence
    end

    def initials(resource)
      return "?" if full_name(resource).blank?
      full_name(resource).first.upcase
    end
  end
end
