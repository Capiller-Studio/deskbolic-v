# frozen_string_literal: true

class DashboardController < ApplicationController
  include Pundit::Authorization
  include CurrentAttributesAccessible
  include AccountStatusGuarded
  include SsoSessionGovernable
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :ensure_subdomain_for_account
  before_action :redirect_if_no_accounts
  before_action :enforce_active_subscription
  before_action :set_unread_counts
  around_action :set_sharding_context

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  layout "dashboard"

  helper_method :current_account, :current_account_user

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
    return @current_account if defined?(@current_account)

    if request.subdomain.present? && request.subdomain != "www"
      @current_account = Account.find_by(identifier: request.subdomain)
    else
      @current_account = nil
    end
  end

  def current_account_user
    return @current_account_user if defined?(@current_account_user)

    @current_account_user = if current_user && current_account
                              current_account.account_users.find_by(user_id: current_user.id)
    end
  end

  def authorize(record, query = nil, **)
    super([ :dashboard, record ], query, **)
  end

  def policy(record)
    super([ :dashboard, record ])
  end

  def policy_scope(scope)
    super([ :dashboard, scope ])
  end

  private

  def ensure_subdomain_for_account
    return unless user_signed_in?

    # Allow accessing apex routes without subdomain redirect, supporting localized routes
    apex_allowed_paths = [ "/workspaces", "/workspace", "/profile" ]
    return if apex_allowed_paths.any? { |p| unlocalized_path == p || unlocalized_path.start_with?("#{p}/") }

    active_accounts = current_user.accounts.active
    if active_accounts.any?
      if request.subdomain.blank? || request.subdomain == "www"
        if active_accounts.count == 1
          redirect_to(root_url(subdomain: active_accounts.first.identifier), allow_other_host: true)
        else
          redirect_to(workspaces_url(subdomain: ""), allow_other_host: true)
        end
      elsif current_account.nil? || !active_accounts.exists?(id: current_account.id)
        if active_accounts.count == 1
          redirect_to(root_url(subdomain: active_accounts.first.identifier), allow_other_host: true, alert: I18n.t("dashboard.workspace.not_authorized", default: "You do not have access to that workspace."))
        else
          redirect_to(workspaces_url(subdomain: ""), allow_other_host: true, alert: I18n.t("dashboard.workspace.not_authorized", default: "You do not have access to that workspace."))
        end
      end
    end
  end

  def redirect_if_no_accounts
    if user_signed_in? && current_user.accounts.active.empty?
      allowed_paths = [ "/workspace", "/workspaces/#{current_user.id}/submitted", "/profile" ]
      redirect_to(workspace_url(subdomain: ""), allow_other_host: true) unless allowed_paths.any? { |p| unlocalized_path == p || unlocalized_path.start_with?("#{p}/") }
    end
  end

  def unlocalized_path
    path = request.path.sub(/\A\/(?:#{Core::SUPPORTED_LOCALES.join('|')})(?=\/|\z)/, "")
    path.empty? ? "/" : path
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

  FEATURE_NAME_MAP = {
    "channels.custom" => "Custom Channels",
    "channels.web_widget" => "Live Chat Channels",
    "channels.contact_form" => "Contact Form Channels",
    "channels.facebook" => "Facebook Channels",
    "channels.whatsapp" => "WhatsApp Channels",
    "channels.instagram" => "Instagram Channels",
    "channels.email" => "Email Channels",
    "channels.twitter" => "Twitter Channels",
    "channels.line" => "LINE Channels",
    "channels.telegram" => "Telegram Channels",
    "channels.sms" => "SMS Channels",
    "sla" => "SLA Policies",
    "sso" => "SSO",
    "scim" => "SCIM Directory Sync",
    "csat" => "CSAT Surveys",
    "custom_csat" => "CSAT Surveys",
    "api_access" => "API Access",
    "custom_fields" => "Custom Fields",
    "custom_domains" => "Custom Domains",
    "custom_roles" => "Custom Roles",
    "identity_sources" => "Identity Sources",
    "business_hours" => "Business Hours",
    "automations" => "Automations",
    "macros" => "Macros",
    "email_templates" => "Email Templates",
    "email_template_layouts" => "Email Template Layouts",
    "help_center_portals" => "Help Center Portals",
    "assignment_policies" => "Assignment Policies",
    "audit_logs" => "Audit Logs"
  }.freeze

  def user_not_authorized(exception)
    policy = exception.policy

    # If the policy failed due to a feature or limit, re-route it to the premium handlers
    if policy.respond_to?(:authorization_failure_reason)
      case policy.authorization_failure_reason
      when :feature_not_enabled
        feature_name = format_feature_name(policy.authorization_failure_feature)
        flash[:alert] = I18n.t("dashboard.billing.feature_not_enabled", feature: feature_name, default: "The feature '%{feature}' is not available on your current plan. Please upgrade to access it.")
        return redirect_to(dashboard_billing_path)
      when :limit_reached
        limit_name = format_limit_name(policy.authorization_failure_limit)
        flash[:alert] = I18n.t("dashboard.billing.limit_reached", limit: limit_name, default: "You have reached your limit for '%{limit}'. Please upgrade your plan for more capacity.")
        return redirect_to(dashboard_billing_path)
      end
    end

    respond_to do |format|
      format.json { render json: { error: I18n.t("dashboard.authorization.not_authorized", default: "You are not authorized to perform this action.") }, status: :forbidden }
      format.all do
        flash[:error] = I18n.t("dashboard.authorization.not_authorized", default: "You are not authorized to perform this action.")
        redirect_back(fallback_location: root_path)
      end
    end
  end

  private

  def format_feature_name(feature_key)
    raw = feature_key.to_s.sub(/_enabled$/, "")
    FEATURE_NAME_MAP[raw] || raw.tr(".", " ").humanize.titleize.gsub(/\bSla\b/, "SLA").gsub(/\bSso\b/, "SSO").gsub(/\bCsat\b/, "CSAT").gsub(/\bApi\b/, "API")
  end

  def format_limit_name(limit_key)
    raw = limit_key.to_s.humanize.titleize
    raw.gsub(/\bSla\b/, "SLA").gsub(/\bSso\b/, "SSO").gsub(/\bCsat\b/, "CSAT").gsub(/\bApi\b/, "API")
  end
end
