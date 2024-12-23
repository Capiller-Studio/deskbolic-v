# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module DashboardHelper
    FLASH_CLASS_MAPPING = {
      "success" => "green",
      "error" => "red",
      "alert" => "blue",
      "notice" => "yellow"
    }.freeze
    DEFAULT_FLASH_CLASS = "dark"

    def flash_alert_type(message_type)
      FLASH_CLASS_MAPPING[message_type] || DEFAULT_FLASH_CLASS
    end
  end
end