# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class RegistrationsController < Devise::RegistrationsController
    layout "auth"

    prepend_before_action :redirect_public_registration, only: [ :new, :create ]

    def registered
      render("dashboard/registrations/registered")
    end

    def new
      redirect_public_registration
    end

    def create
      redirect_public_registration
    end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sign_up_path_for(resource)
      account = @registered_account || resource.accounts.first
      subdomain = account&.identifier || ""

      if account.present? && account.subscriptions.empty?
        new_subscription_url(
          {
            subdomain: subdomain,
            plan_id: @selected_plan_id,
            billing_cycle: @selected_billing_cycle
          }.compact
        )
      else
        root_url(subdomain: subdomain)
      end
    end

    def after_inactive_sign_up_path_for(_resource)
      registered_path
    end

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name account_id remember_me password])
    end


    private

    def check_registration_enabled
      return unless ENV["DISABLE_REGISTRATION"] == "true"

      redirect_to new_user_session_path, alert: t("auth.registration.registration_disabled", default: "Registration is temporarily closed.")
    end

    def redirect_public_registration
      redirect_to(
        ENV.fetch("WORKSPACE_ADMIN_URL", "https://workspace-admin.capiller.com"),
        allow_other_host: true,
        status: :see_other
      )
    end
    def clear_onboarding_cookies
      cookies.delete(:ref)
      cookies.delete(:ref_code)
      cookies.delete(:ref_sc)
      cookies.delete(:selected_plan_id)
      cookies.delete(:selected_billing_cycle)
      cookies.delete(:currency)
      cookies.delete(:selected_currency)
      cookies.delete(:deskbolic_referral_code)
    end

    def selected_plan_id
      params[:plan_id].presence || cookies[:selected_plan_id].presence
    end

    def selected_billing_cycle
      cycle = params[:billing_cycle].presence || cookies[:selected_billing_cycle].presence || "monthly"
      Subscription.billing_cycles.key?(cycle.to_s) ? cycle.to_s : "monthly"
    end

    def create_selected_subscription(account)
      return if account.blank? || @selected_plan_id.blank?

      plan = Plan.available.find_by(id: @selected_plan_id, currency: account.currency)
      return if plan.blank? || account.subscriptions.current.exists?

      Billing::SubscriptionCreator.call(
        account: account,
        plan: plan,
        billing_cycle: @selected_billing_cycle.to_sym,
        quantity: [ account.users_count, plan.min_users ].max
      )
      @selected_subscription_created = true
    rescue StandardError => e
      Rails.logger.warn(
        "Failed to create onboarding subscription for account #{account&.id}: #{e.class} - #{e.message}"
      )
      @selected_subscription_created = false
    end
  end
end
