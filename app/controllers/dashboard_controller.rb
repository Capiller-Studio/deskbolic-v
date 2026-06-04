# frozen_string_literal: true

class DashboardController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_if_no_accounts
  before_action :enforce_active_subscription

  include Pundit
  include CurrentAttributesAccessible
  include Pagy::Backend

  layout "dashboard"

  helper_method :current_account

  def pundit_user
    current_user
  end

  def current_account
    @current_account ||= current_user.accounts.find_by(id: session[:current_account_id])
  end

  def authorize(record, query = nil)
    super([ :dashboard, record ], query)
  end

  private

  def redirect_if_no_accounts
    if user_signed_in? && current_user.accounts.empty?
      redirect_to(workspace_path) unless request.path == workspace_path || request.path == submitted_path(current_user.id)
    end
  end

  def enforce_active_subscription
    return unless current_account

    if current_account.subscriptions.empty?
      unless %w[subscriptions sessions].include?(controller_name)
        redirect_to new_subscription_path, alert: I18n.t("dashboard.billing.no_plan_warning", default: "Please select a plan to continue.")
      end
      return
    end

    sub = current_account.subscriptions.order(created_at: :desc).first
    return unless sub
    return if sub.plan.free?

    if sub.past_due? || sub.cancelled?
      unless %w[billings payment_methods sessions].include?(controller_name)
        redirect_to dashboard_billing_path, alert: I18n.t("dashboard.billing.past_due_warning", default: "Your subscription is past due. Please update your payment method to restore access.")
      end
    elsif sub.trialing? && current_account.payment_methods.active_methods.empty?
      dismissed_at = session[:billing_warning_dismissed_at]
      if dismissed_at.blank? || dismissed_at.to_time < 1.day.ago
        @billing_warning_message = I18n.t("dashboard.billing.trial_ending_warning", days: sub.days_until_trial_end, default: "Your trial ends in %{days} days. Please add a payment method to avoid interruption.")
      end
    end
  end
end
