# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_subdomain_for_account
  before_action :redirect_if_no_accounts
  before_action :enforce_active_subscription
  before_action :set_unread_counts
  around_action :set_sharding_context

  include Pundit::Authorization
  include CurrentAttributesAccessible
  include Pagy::Backend

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  layout "dashboard"

  helper_method :current_account

  private

  def set_sharding_context(&)
    if current_account
      current_account.with_shard(&)
    else
      yield
    end
  end

  def set_unread_counts
    if current_user && current_account
      @unread_counts = UnreadCounts::Current.call(member: current_user, account_id: current_account.id)
    else
      @unread_counts = { conversations: {}, inboxes: {}, mentions: 0, unread_conversation_ids: [] }
    end
  end

  def pundit_user
    current_user
  end

  def current_account
    configure_account
  end

  def authorize(record, query = nil)
    super([ :dashboard, record ], query)
  end

  def policy(record)
    super([ :dashboard, record ])
  end

  def policy_scope(scope)
    super([ :dashboard, scope ])
  end

  private

  def ensure_subdomain_for_account
    return unless user_signed_in? && user_has_accounts?
    # Already viewing the selected workspace's subdomain — nothing to do
    return if current_account&.identifier == request.subdomain

    # Redirect to the selected workspace's subdomain when accessing the naked domain
    if request.subdomain.blank? || request.subdomain == "www"
      redirect_to(root_url(subdomain: current_account.identifier), allow_other_host: true) if current_account
    elsif unauthorized_subdomain? && current_account
      # Subdomain is provided but unknown or not one of the user's workspaces
      redirect_to(
        root_url(subdomain: current_account.identifier),
        allow_other_host: true,
        alert: "Account not found or access denied."
      )
    end
  end

  def unauthorized_subdomain?
    account = account_from_subdomain
    account.nil? || !current_user.accounts.exists?(account.id)
  end

  def user_has_accounts?
    return @user_has_accounts if defined?(@user_has_accounts)

    @user_has_accounts = current_user.accounts.exists?
  end

  def redirect_if_no_accounts
    return unless user_signed_in? && !user_has_accounts?

    redirect_to(workspace_url(subdomain: "")) unless request.path == workspace_path || request.path == submitted_path(current_user.id)
  end

  def enforce_active_subscription
    return unless current_account

    if current_account.subscriptions.empty?
      unless %w[subscriptions sessions].include?(controller_name)
        redirect_to(new_subscription_path, alert: I18n.t("dashboard.billing.no_plan_warning", default: "Please select a plan to continue."))
      end
      return
    end

    sub = current_account.subscriptions.order(created_at: :desc).first
    return unless sub
    return if sub.plan.free?

    if sub.past_due? || sub.cancelled? || sub.expired?
      unless %w[billings payment_methods subscriptions sessions].include?(controller_name)
        redirect_to(dashboard_billing_path, alert: I18n.t("dashboard.billing.past_due_warning", default: "Your subscription is past due. Please update your payment method to restore access."))
      end
    elsif sub.trialing? && current_account.payment_methods.active_methods.empty?
      dismissed_at = session[:billing_warning_dismissed_at]
      if dismissed_at.blank? || dismissed_at.to_time < 1.day.ago
        days_left = sub.days_until_trial_end
        if days_left <= 0
          @billing_warning_message = I18n.t("dashboard.billing.trial_expired_warning", default: "Your trial has ended. Please add a payment method to continue using your workspace.")
        else
          @billing_warning_message = I18n.t("dashboard.billing.trial_ending_warning", days: days_left, default: "Your trial ends in %{days} days. Please add a payment method to avoid interruption.")
        end
      end
    end
  end

  def user_not_authorized(exception)
    policy = exception.policy

    # If the policy failed due to a feature or limit, re-route it to the premium handlers
    if policy.respond_to?(:authorization_failure_reason)
      case policy.authorization_failure_reason
      when :feature_not_enabled
        feature_name = policy.authorization_failure_feature.to_s.sub(/_enabled$/, "").humanize.titleize
        flash[:alert] = I18n.t("dashboard.billing.feature_not_enabled", feature: feature_name, default: "The feature '%{feature}' is not available on your current plan. Please upgrade to access it.")
        return redirect_to(dashboard_billing_path)
      when :limit_reached
        flash[:alert] = I18n.t("dashboard.billing.limit_reached", limit: policy.authorization_failure_limit.to_s.humanize.titleize, default: "You have reached your limit for '%{limit}'. Please upgrade your plan for more capacity.")
        return redirect_to(dashboard_billing_path)
      end
    end

    flash[:error] = I18n.t("dashboard.authorization.not_authorized", default: "You are not authorized to perform this action.")
    redirect_back(fallback_location: root_path)
  end

  def record_not_found(exception)
    raise(exception) unless request.format.html?

    flash[:alert] = I18n.t("dashboard.record_not_found", default: "That record doesn't exist in the selected workspace.")
    redirect_to(root_path)
  end
end
