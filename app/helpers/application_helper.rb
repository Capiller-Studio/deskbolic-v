# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  include Pundit::Authorization

  # Unified view helper for Pundit
  # Usage: if can?(:edit, @item) ...
  def can?(action, record)
    policy(record).public_send(:"#{action}?")
  end

  # Renders an upgrade lock badge if a feature is not enabled
  def plan_upgrade_bubble(feature, compact: false)
    return if current_account&.feature_enabled?(feature)

    if compact
      return content_tag(:span, inline_svg_tag("red_lock.svg"), class: "plan-upgrade-lock", title: "Upgrade", aria: { label: "Upgrade" })
    end

    content_tag(:span, "🔒 Upgrade", style: "font-size: 10px; color: #ef4444; margin-left: 6px; display: inline-block; padding: 2px 6px; background: #fee2e2; border-radius: 4px; font-weight: 600;")
  end

  def current_account
    Current.account
  end

  def account_time(value)
    return if value.nil?

    time_zone = ActiveSupport::TimeZone[current_account&.timezone] || ActiveSupport::TimeZone["UTC"]
    value.in_time_zone(time_zone)
  end
end
