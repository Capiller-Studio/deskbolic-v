# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class RegistrationsController < Devise::RegistrationsController
    layout "dashboard"
    # invisible_captcha only: :create, honeypot: :gift_vcode, scope: :user
    # skip_before_action :require_no_authentication, only: [:new, :create]
    # before_action :require_no_authentication, only: [:new, :create]
    before_action :configure_sign_up_params, only: [:create]

    # before_action :configure_account_update_params, only: [:update]

    # GET /resource/sign_up
    # def new
    #   super
    # end

    # POST /resource
    def create
      build_resource(sign_up_params.merge)
      resource.address = Address.create
      
      if resource.save
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
    
    # GET /resource/edit
    # def edit
    #   super
    # end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    # def build_resource(hash = {})
    #   super
    #   resource.perform_name_validation = true
    #   resource.password_in_confirmation_mail = true

    #   ref_code = cookies[:ref_code]
    #   return resource unless ref_code

    #   resource.referred_by = User.find_by(referral_code: ref_code)

    #   channel_uuid = cookies.signed[:ref_sc]
    #   return resource unless channel_uuid

    #   resource.source_channel = SourceChannel.find_by(
    #     uuid: channel_uuid,
    #     account_id: resource.referred_by&.account_id
    #   )
    #   resource
    # end

    protected

    # def require_no_authentication
    #   redirect_to workspace_path if current_user
    # end
    
    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_up_params
      # devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
      devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :account_id, :remember_me, :password])
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_account_update_params
    #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    # end

    # The path used after sign up.
    def after_sign_up_path_for(_resource)
      workspace_path
    end

    # The path used after sign up for inactive accounts.
    def after_inactive_sign_up_path_for(_resource)
      
    end
  end
end
