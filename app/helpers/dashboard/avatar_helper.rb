# frozen_string_literal: true

module Dashboard
  module AvatarHelper
    def avatar_fallback_color_class(name)
      seed = name.to_s.strip.downcase
      index = seed.present? ? seed.each_byte.sum % 8 : 0

      "avatar-fallback-#{index + 1}"
    end
  end
end
