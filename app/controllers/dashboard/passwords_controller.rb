# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class PasswordsController < Devise::PasswordsController
    layout "auth"

    skip_before_action :require_no_authentication, only: %i[edit update]
    prepend_before_action :sign_out_if_resetting_password, only: %i[edit update]

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    private

    def sign_out_if_resetting_password
      return if params[:reset_password_token].blank?

      sign_out(:user) if user_signed_in?
    end

    protected

    def after_resetting_password_path_for(resource)
      if request.subdomain.present? && request.subdomain != "www"
        subdomain_account = Account.find_by(identifier: request.subdomain)
        if subdomain_account && resource.accounts.exists?(id: subdomain_account.id)
          return root_url(subdomain: subdomain_account.identifier)
        end
      end

      if resource.accounts.empty?
        workspace_url(subdomain: "")
      elsif resource.accounts.count == 1
        root_url(subdomain: resource.accounts.first.identifier)
      else
        workspaces_url(subdomain: "")
      end
    end

    def after_sending_reset_password_instructions_path_for(_resource_name)
      new_user_session_url(subdomain: "")
    end
  end
end
