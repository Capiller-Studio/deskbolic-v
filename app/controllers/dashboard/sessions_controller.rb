# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class SessionsController < Devise::SessionsController
    layout "auth"

    include CurrentAttributesAccessible

    before_action :authenticate_user!, only: :switch

    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    # def new
    #   # if flash[:alert] == I18n.t("devise.failure.unconfirmed")
    #   #   @unconfirmed_email = true
    #   #   # flash[:alert] = nil
    #   # end
    #   # @warden_options = request.env["warden.options"] || {}
    #   # super
    # end

    # POST /resource/sign_in
    def create
      super do |resource|
        account = oldest_account_for(resource)
        persist_selected_account(account) if account
      end
    end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    def switch
      account = account_from_id(params[:id])

      if account && current_user.accounts.exists?(account.id)
        persist_selected_account(account)
        redirect_to(root_url)
      else
        redirect_to(root_url, alert: I18n.t("dashboard.authorization.not_authorized", default: "You are not authorized to perform this action."))
      end
    end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sign_in_path_for(resource)
      account = oldest_account_for(resource)

      if account
        root_url(subdomain: account.identifier)
      else
        workspace_url(subdomain: "")
      end
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
    # end


    private

    def oldest_account_for(resource)
      resource.accounts.order(:created_at).first
    end

    # def sign_in_params
    #   # params.require(:user).permit(:email, :password, :remember_me, :account_id)
    #   params.permit(:email, :password, :remember_me, :account_id)
    # end
  end
end
