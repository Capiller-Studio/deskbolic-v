# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class RegistrationsController < Devise::RegistrationsController
    layout "auth"
    invisible_captcha only: :create, honeypot: :gift_vcode, scope: :user

    before_action :check_registration_enabled, only: [ :new, :create ]

    def check_email
      exists = User.exists?(email: params[:email])
      render(json: { exists: exists })
    end

    def registered
      render("dashboard/registrations/registered")
    end

    def create
      # The form data from the wizard will come nested under user (or account)
      registration_params = {
        email: params[:user][:email],
        password: params[:user][:password],
        first_name: params[:user][:first_name],
        last_name: params[:user][:last_name],
        country: params[:country],
        account_name: params[:account_name],
        currency: params[:currency],
        shard_key: params[:shard_key],
        locale: params[:account_locale],
        user_locale: I18n.locale,
        invitation_token: params[:invitation_token],
        as_affiliate: false # Modify if needed
      }

      result = Accounts::RegistrationService.call(**registration_params)

      if result.success?
        user = result.user
        @selected_plan_id = selected_plan_id
        @selected_billing_cycle = selected_billing_cycle

        referral_code = params[:ref_code].presence || cookies[:ref_code]

        if referral_code.present? && result.account.present?
          Affiliates::Referrals::Tracker.call(account: result.account, referral_code: referral_code)
        end

        create_selected_subscription(result.account)

        if user.active_for_authentication?
          set_flash_message!(:notice, :signed_up)
          sign_up(resource_name, user)
          if result.account
            session[:current_account_id] = result.account.id
            cookies.signed[:current_account_id] = { value: result.account.id, expires: 1.year.from_now }
          end

          clear_onboarding_cookies

          respond_to do |format|
            format.html { redirect_to(after_sign_up_path_for(user), status: :see_other) }
            format.turbo_stream { redirect_to(after_sign_up_path_for(user), status: :see_other) }
          end
        else
          set_flash_message!(:notice, :"signed_up_but_#{user.inactive_message}")
          expire_data_after_sign_in!
          clear_onboarding_cookies

          respond_to do |format|
            format.html { redirect_to(after_inactive_sign_up_path_for(user), status: :see_other) }
            format.turbo_stream do
              render(turbo_stream: turbo_stream.replace(
                "registration-wizard",
                partial: "dashboard/registrations/registered_success"
              ))
            end
          end
        end
      else
        @errors = result.errors
        # Let turbo handle the error state rendering, or we can just render the form again
        respond_to do |format|
          format.html do
            flash.now[:alert] = @errors.map { |e| e[:message] }.join(", ")
            render(:new, status: :unprocessable_entity)
          end
          format.turbo_stream do
            render(turbo_stream: turbo_stream.replace("registration-form-errors", partial: "dashboard/registrations/errors", locals: { errors: @errors }))
          end
        end
      end
    end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sign_up_path_for(resource)
      if @selected_plan_id.present? && !@selected_subscription_created
        new_subscription_url(
          subdomain: resource.accounts.first&.identifier || "",
          plan_id: @selected_plan_id,
          billing_cycle: @selected_billing_cycle
        )
      else
        if resource.accounts.any?
          root_url(subdomain: resource.accounts.first.identifier)
        else
          root_url(subdomain: "")
        end
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
      if ENV.fetch("DISABLE_REGISTRATION", "true") == "true"
        authenticate_or_request_with_http_basic("Deskbolic Private Beta") do |username, password|
          username == "techbolic" && password == "betaaccess2026"
        end
      end
    end
    def clear_onboarding_cookies
      cookies.delete(:ref_code)
      cookies.delete(:ref_sc)
      cookies.delete(:selected_plan_id)
      cookies.delete(:selected_billing_cycle)
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
