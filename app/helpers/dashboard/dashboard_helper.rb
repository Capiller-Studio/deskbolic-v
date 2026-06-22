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
    STATUS_CLASS_MAPPING = {
      "active" => "green",
      "offline" => "gray",
      "inactive" => "red",
      "archived" => "gray"
    }.freeze
    STRATEGY_MAPPING = {
      "round_robin" => "🔄",
      "load_balanced" => "⚖️",
      "skills_based" => "🎯",
      "manual" => "✋"
    }.freeze
    
    DEFAULT_FLASH_CLASS = "green"
    DEFAULT_STATUS_CLASS = "green"

    def flash_alert_type(message_type)
      FLASH_CLASS_MAPPING[message_type] || DEFAULT_FLASH_CLASS
    end
    
    def member_status_class(status)
      STATUS_CLASS_MAPPING[status] || DEFAULT_STATUS_CLASS
    end

    def strategy_icon(strategy)
      STRATEGY_MAPPING[strategy] || "📋"
    end
  end
end
