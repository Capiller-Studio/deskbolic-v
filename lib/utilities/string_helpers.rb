# frozen_string_literal: true

module Utilities
  module StringHelpers
    def change_encoding(value, encoding: "UTF-8")
      return "" if value.blank?

      current_encoding = value.encoding.name
      return value if current_encoding == encoding

      value.encode(current_encoding, encoding, invalid: :replace, undef: :replace, replace: "")
    rescue StandardError
      ""
    end
  end
end
