# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module AccountStatusGuarded
  extend ActiveSupport::Concern

  included do
    before_action :ensure_account_active
  end

  private

  def ensure_account_active
    return unless current_account
    return if current_account.active? || current_account.suspended?

    # Bypass check for workspace switching, profile management, and session destruction
    allowed_controllers = %w[sessions workspace workspaces profile]
    return if allowed_controllers.include?(controller_name)

    flash[:alert] = I18n.t(
      "dashboard.workspace.deactivated_notice",
      default: "This workspace has been deactivated and is pending deletion."
    )

    if current_user.accounts.active.where.not(id: current_account.id).exists?
      redirect_to(workspaces_url(subdomain: ""), allow_other_host: true)
    else
      redirect_to(workspace_url(subdomain: ""), allow_other_host: true)
    end
  end
end
