# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class SessionsController < Devise::SessionsController
    layout "auth"
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
        if resource.accounts.any?
          account_id = resource.accounts.first.id
          session[:current_account_id] = account_id
          cookies.signed[:current_account_id] = { value: account_id, expires: 1.year.from_now }
        end
      end
    end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    protected

    def after_sign_in_path_for(resource)
      if resource.accounts.any?
        super
      else
        workspace_path
      end
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
    # end

    def switch
      account = Account.find(params[:id])
      if current_user.accounts.include?(account)
        session[:current_account_id] = account.id
        cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
        redirect_to(root_url)
      else
        redirect_to(accounts_path, alert: "You are not authorized")
      end
    end

    private

    # def sign_in_params
    #   # params.require(:user).permit(:email, :password, :remember_me, :account_id)
    #   params.permit(:email, :password, :remember_me, :account_id)
    # end
  end
end
