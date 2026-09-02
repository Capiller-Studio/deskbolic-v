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
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sign_in_path_for(resource)
      # 1. If signing in on a specific account subdomain
      if request.subdomain.present? && request.subdomain != "www"
        subdomain_account = Account.find_by(identifier: request.subdomain)
        if subdomain_account && resource.accounts.exists?(id: subdomain_account.id)
          return root_url(subdomain: subdomain_account.identifier)
        end
      end

      # 2. Apex domain login routing
      if resource.accounts.empty?
        workspace_url(subdomain: "")
      elsif resource.accounts.count == 1
        root_url(subdomain: resource.accounts.first.identifier)
      else
        workspaces_url(subdomain: "")
      end
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
    # end

    private

    # def sign_in_params
    #   # params.require(:user).permit(:email, :password, :remember_me, :account_id)
    #   params.permit(:email, :password, :remember_me, :account_id)
    # end
  end
end
