# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class RegistrationsController < Devise::RegistrationsController
    layout "auth"
    invisible_captcha only: :create, honeypot: :gift_vcode, scope: :user

    def check_email
      exists = User.exists?(email: params[:email])
      render json: { exists: exists }
    end

    def registered
      render "dashboard/registrations/registered"
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
        
        if cookies[:ref_code].present? && result.account.present?
          Affiliates::Referrals::Tracker.call(account: result.account, referral_code: cookies[:ref_code])
          cookies.delete(:ref_code)
          cookies.delete(:ref_sc)
        end

        if user.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, user)
          if result.account
            session[:current_account_id] = result.account.id
            cookies.signed[:current_account_id] = { value: result.account.id, expires: 1.year.from_now }
          end

          respond_to do |format|
            format.html { redirect_to after_sign_up_path_for(user), status: :see_other }
            format.turbo_stream { redirect_to after_sign_up_path_for(user), status: :see_other }
          end
        else
          set_flash_message! :notice, :"signed_up_but_#{user.inactive_message}"
          expire_data_after_sign_in!

          respond_to do |format|
            format.html { redirect_to after_inactive_sign_up_path_for(user), status: :see_other }
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                "registration-wizard",
                partial: "dashboard/registrations/registered_success"
              )
            end
          end
        end
      else
        @errors = result.errors
        # Let turbo handle the error state rendering, or we can just render the form again
        respond_to do |format|
          format.html do
            flash.now[:alert] = @errors.map { |e| e[:message] }.join(", ")
            render :new, status: :unprocessable_entity
          end
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("registration-form-errors", partial: "dashboard/registrations/errors", locals: { errors: @errors })
          end
        end
      end
    end

    protected

    def after_sign_up_path_for(_resource)
      root_path
    end

    def after_inactive_sign_up_path_for(_resource)
      registered_path
    end

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name account_id remember_me password])
    end
  end
end
