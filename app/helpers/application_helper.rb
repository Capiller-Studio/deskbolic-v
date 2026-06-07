# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Unified view helper for Pundit
  # Usage: if can?(:edit, @item) ...
  def can?(action, record)
    policy(record).public_send(:"#{action}?")
  end

  # Renders an upgrade lock badge if a feature is not enabled
  def plan_upgrade_bubble(feature)
    return if current_account&.feature_enabled?(feature)

    content_tag(:span, "🔒 Upgrade", style: "font-size: 10px; color: #ef4444; margin-left: 6px; display: inline-block; padding: 2px 6px; background: #fee2e2; border-radius: 4px; font-weight: 600;")
  end
end
